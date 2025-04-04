# /home/flavio/.arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/bin/avrdude -C/home/flavio/.arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/etc/avrdude.conf -q -q -V -patmega328p -carduino -P/dev/ttyUSB0 -b57600 -D -Uflash:w:/home/flavio/.cache/arduino/sketches/C7AC041A230A29A664EDEC93374FFF48/n64-reset.ino.hex:i

CC=avr-gcc
OBJCOPY=avr-objcopy
OBJDUMP=avr-objdump
AVRSIZE=avr-size

MCU=atmega328p
F_CPU=8000000UL

AVRDUDE=avrdude
AVRDUDE_FLAGS=-P/dev/ttyUSB0 -b57600 -carduino -p$(MCU) -D

CFLAGS=-Os -Wall -Wextra -std=c17 -mmcu=$(MCU) -DF_CPU=$(F_CPU) -g
ASFLAGS=-mmcu=$(MCU) -x assembler-with-cpp

OBJS=n64-reset.o controller-sniff.o

all: n64-reset.hex

%.o: %.S
	$(CC) $(ASFLAGS) -c -o $@ $<

n64-reset.elf: $(OBJS)
	$(CC) $(CFLAGS) $^ --output $(@F)

n64-reset.hex: n64-reset.elf
	$(OBJCOPY) -O ihex -j .text -j .data $< $@
	$(AVRSIZE) $@

flash: n64-reset.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -Uflash:w:$<:i

clean:
	rm -f n64-reset.hex n64-reset.elf $(OBJS)
