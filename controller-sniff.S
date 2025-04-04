#include <avr/io.h>
#include "defines.h"

#define expected_pattern_low r24
#define expected_pattern_high r25
#define pattern r18
#define pattern2 r19
#define left r20

.macro wait_for_falling
	;wait_for_high_wff:
	1:
		sbis N64_CONTROLLER_PIN_ADDR, N64_CONTROLLER_INDEX;
		rjmp 1b; wait_for_high_wff
	;wait_for_low_wff:
	2:
		sbic N64_CONTROLLER_PIN_ADDR, N64_CONTROLLER_INDEX;
		rjmp 2b; wait_for_low_wff
.endm

.macro read_3_bitbit_pattern
		; Reads a 3 bitbit pattern and stores it in pattern
		wait_for_falling

		; First bitbit is read and is 0. wait_for_falling was 2 cycles, 6 left
		clr pattern;
		nop;
		nop;
		nop;
		nop;
		nop;

		; Read second bitbit
		sbic N64_CONTROLLER_PIN_ADDR, N64_CONTROLLER_INDEX;
		ori pattern, 1;
		lsl pattern;
		nop;
		nop;
		nop;
		nop;
		nop;

		; Read third bitbit
		sbic N64_CONTROLLER_PIN_ADDR, N64_CONTROLLER_INDEX;
		ori pattern, 1;
.endm

.macro read_byte
		; Reads 8 bits into pattern
		ldi left, 8;

	1:
		wait_for_falling

		; wait_for_falling took 2 cycles, 6 left before next bitbit
		; Most significant bit first
		lsl pattern;
		nop;
		nop;
		nop;
		nop;
		nop;

		; The second bitbit is enough to tell if it's zero or one
		sbic N64_CONTROLLER_PIN_ADDR, N64_CONTROLLER_INDEX;
		ori pattern, 0x1;
		subi left, 1;
		brne 1b; read_next_bit_rb
.endm

.section .text

.global wait_for_controller_pattern
wait_for_controller_pattern:
		; Sniffs the controller data line, waiting for a state request by the
		; console. Followed by a reply by the controller.
		; Bits are served at 250 khZ, composed of 3 or 4 bitbits served at 1 mHz.
		; Each bitbit is 8 cycles
		;
		; Patterns:
		; 0: 0001
		; 1: 0111
		; Console stop: 011
		; Controller stop: 001
		cli

	resync:
	wait_for_long_silence:
		; Inacurately detects ~100us of silence (5*160 cycles of HIGH)
		; There is no science to this, but there is no way to accuratelly ensure
		; the console will be the next one communicating, since third-party
		; controllers might send invalid stopping sequences.
		ldi left, 161;
	keep_waiting_for_long_silence:
		sbis N64_CONTROLLER_PIN_ADDR, N64_CONTROLLER_INDEX;
		rjmp wait_for_long_silence;
		subi left, 1;
		brne keep_waiting_for_long_silence;

	wait_for_console_command:
		; Controller is done, next message should be from the console.
		; Each command is a byte followed by the console stop sequence.
		read_byte;
		; Command 0x1 queries the state of the controller
		cpi pattern, 0x1;
		brne resync;

		; The command should be followed by a console stop sequence
	confirm_console_stop_pattern:
		read_3_bitbit_pattern;
		cpi pattern, 0x3;
		brne resync;

	read_controller_state:
		; The controller replies with 4 bytes followed by the controller end
		; pattern. We only need the first 2 bytes to match the button pattern.
		read_byte;
		mov pattern2, pattern;
		read_byte;

	match_state_pattern:
		cp pattern2, expected_pattern_low;
		brne bad_pattern_matched;
		cp pattern, expected_pattern_high;
		brne bad_pattern_matched;
		rjmp correct_pattern_found;

	bad_pattern_matched:
		; Needed. resync is too far from resync
		rjmp resync;

	correct_pattern_found:
		sei
		; Always return success
		ldi r24, 1;
		ret
