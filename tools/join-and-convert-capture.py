#! /bin/env python3

import sys
import vcd
import statistics

# Ugly and hacky. Merges conflicts in the same timestamp

V_THRESHOLD=3300./2.
DELAY=1000*1000
END_EXTRA=1000*1000

base_timestamp = DELAY
samples = {}
for capture_path in sys.argv[1:]:
    with open(capture_path) as capture:
        time_interval = None
        for line in capture:
            line = line.strip()
            if line == "":
                break

            line = list(map(str.strip, line.split(":,")))
            if line[0] == "Time interval":
                if line[1][-2:] != "us":
                    raise ValueError(
                        f"Time interval unit is not us in {capture_path}")
                time_interval = float(line[1][:-2])

        if time_interval is None:
            raise ValueError(
                f"Time interval missing from {capture_path}")

        # Discard header
        capture.readline()

        for line in capture:
            line = line.strip().split(",")
            timestamp = round((int(line[0])-1)*time_interval*1000)
            if timestamp+base_timestamp not in samples:
                samples[timestamp+base_timestamp] = []
            samples[timestamp+base_timestamp].append(float(line[1]))
        base_timestamp += timestamp

with vcd.writer.VCDWriter(sys.stdout, timescale="1 ns") as writer:
    controller_wire = writer.register_var("logic", "iogB_2", "wire", 1, init=1)

    for timestamp, reads in sorted(samples.items()):
        v = statistics.mean(reads)
        val = 1 if v > V_THRESHOLD else 0
        writer.change(controller_wire, timestamp, val)
    writer.change(controller_wire, timestamp+END_EXTRA, "x")
