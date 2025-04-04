#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "defines.h"
#include "controller-sniff.h"

enum {
  BUTTON_DR = 1<<0,
  BUTTON_DL = 1<<1,
  BUTTON_DD = 1<<2,
  BUTTON_DU = 1<<3,
  BUTTON_START = 1<<4,
  BUTTON_Z = 1<<5,
  BUTTON_B = 1<<6,
  BUTTON_A = 1<<7,
  BUTTON_CR = 1<<8,
  BUTTON_CL = 1<<9,
  BUTTON_CD = 1<<10,
  BUTTON_CU = 1<<11,
  BUTTON_R = 1<<12,
  BUTTON_L = 1<<13,
  BUTTON_RESERVED = 1<<14,
  BUTTON_RESET = 1<<15,
};

void n64_reset() {
  // BUILTIN_LED high
  BUILTIN_LED_PORT |= 1 << BUILTIN_LED_INDEX;

  // N64_RESET as input and low
  N64_RESET_REGISTER &= ~(1 << N64_RESET_INDEX);
  N64_RESET_PORT &= ~(1 << N64_RESET_INDEX);

  // N64_RESET as output
  N64_RESET_REGISTER |= 1 << N64_RESET_INDEX;

  _delay_ms(100);
  // N64_RESET as input
  N64_RESET_REGISTER &= ~(1 << N64_RESET_INDEX);

  _delay_ms(RESET_COOLDOWN_MS);
  // BUILTIN_LED low
  BUILTIN_LED_PORT &= ~(1 << BUILTIN_LED_INDEX);
}

int main() {
  // N64_CONTROLLER as input
  N64_CONTROLLER_REGISTER &= ~(1 << N64_CONTROLLER_INDEX);

  // N64_RESET as input and low
  N64_RESET_REGISTER &= ~(1 << N64_RESET_INDEX);
  N64_RESET_PORT &= ~(1 << N64_RESET_INDEX);

  // BUILTIN_LED as output and low
  BUILTIN_LED_REGISTER |= 1 << BUILTIN_LED_INDEX;
  BUILTIN_LED_PORT &= ~(1 << BUILTIN_LED_INDEX);

  for (;;) {
    // Ensure a clear state is detected at some point before the reset combo,
    // to prevent loops if holding the buttons down
    wait_for_controller_pattern(0);
    wait_for_controller_pattern(RESET_COMBO);
    n64_reset();
  }

  return 0;
}
