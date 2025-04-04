#! /bin/env python3

import vcd
import sys

BITBIT_LEN=1
CONSOLE_END_PATTERN="011"
CONTROLLER_END_PATTERN="001"

class Spitter(object):
    def __init__(self, writer, wire, offset=0):
        self.writer = writer
        self.wire = wire
        self.offset = offset

    def advance(self, amount):
        self.offset += amount

    def spit_byte(self, byte):
        ps = ["0001", "0111"]
        for _ in range(8):
            self.spit_bitbit_pattern(ps[(byte>>7)&1])
            byte <<= 1

    def spit_bitbit_pattern(self, pattern):
        vs = {"0": 0, "1": 1}
        for c in pattern:
            self.writer.change(self.wire, self.offset, vs[c])
            self.offset += BITBIT_LEN

    def end(self):
        self.offset += 10000
        self.writer.change(self.wire, self.offset, 0)


with vcd.writer.VCDWriter(sys.stdout, timescale="1 us") as writer:
    controller_wire = writer.register_var("logic", "iogB_2", "wire", 1,
        init=1)
    spitter = Spitter(writer, controller_wire, 1000)
    spitter.spit_bitbit_pattern(CONTROLLER_END_PATTERN)

    spitter.advance(32)
    spitter.spit_byte(0x1)
    spitter.spit_bitbit_pattern(CONSOLE_END_PATTERN)

    spitter.spit_byte(0x0)
    spitter.spit_byte(0x0)
    spitter.spit_byte(0x0)
    spitter.spit_byte(0x0)
    spitter.spit_bitbit_pattern(CONTROLLER_END_PATTERN)

    spitter.advance(256)
    spitter.spit_byte(0x1)
    spitter.spit_bitbit_pattern(CONSOLE_END_PATTERN)

    spitter.spit_byte(0xe0)
    spitter.spit_byte(0x30)
    spitter.spit_byte(0x0)
    spitter.spit_byte(0x0)
    spitter.spit_bitbit_pattern(CONTROLLER_END_PATTERN)

    spitter.end()
