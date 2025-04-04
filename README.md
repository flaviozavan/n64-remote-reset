# Minimalist Nintendo 64 Remote Reset

A remote reset solution for the Nintendo 64 using only an Arduino Pro Mini.

*Use this at your own risk, understand that I don't know what I am doing.*

### Required hardware
- Arduino Pro Mini 3.3v 8mHz

Make sure it's 3.3v and 8mHz. The 5v version can't be wired to the N64 in the same way, and any clock other than 8mHz will require changes to the cycle accurate code.

### Helpful hardware
- USB FTDI to 3.3v serial

Since the Arduino Pro Mini does not have a USB port, something similar to this is necessary to program it. Make sure it's able to communicate at 3.3v.

### Customizing

The default reset combo is `A+B+Z+R+L`, and the default cool down time between resets is 5 seconds. These can be changed by editing `defines.h`. Keep in mind that [combos containing `R+L+Start` might have to match the reset bit instead](https://www.qwertymodo.com/hardware-projects/n64/n64-controller).

### Compiling

`make` or use the `.hex` release

The code is made to work with `avr-gcc`, along with `avr-libc` and `avr-binutils`.

The `Makefile` is quite short and easily modified to take into account unusual paths.

### Flashing

`make flash`

Flashing can be done using `avrdude`. `make flash` provides some sensible defaults, which can be changed by editing the file if they don't match your setup.

One quirk of working with the Arduino Pro Mini, is that it often doesn't respond to the commands sent by `avrdude`. The easiest workaround is to hold the reset button on the board, run `make flash`, then let go of the button.

### Development

Development can benefit from the use of [simavr](https://github.com/buserror/simavr) and avr-gdb.

The python scripts in `tools` can generate synthetic signals or convert and concatenate captures from Owon oscilloscopes. The created `.vcd` files that can be visualized in [gtkwave](https://gtkwave.sourceforge.net/) and used as input for `simavr`.

Sample workflow:

`simavr -f 8000000 --mcu atmega328p n64-reset.elf -i /tmp/spliced-capture.vcd -g`
Followed by connecting with gdb:
`gdb n64-reset.elf -ex "target remote :1234" -ex "set disassemble-next-line on"`

### Wiring

|Arduino|N64|
|--|--|
|VCC|Controller Port 1 3.3v|
|GND|Controller Port 1 Ground|
|D10|Controller Port 1 Data|
|D11|Reset Ground|


![Wiring (not to scale)](/img/wiring.jpg)
