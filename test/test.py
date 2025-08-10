# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
from dataclasses import dataclass
from PIL import Image

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 25, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Frame 0
    await dump_frame(dut, "frames/f0.png")
    dut._log.info("Frame 0")
    # Frame 1
    await dump_frame(dut, "frames/f1.png")
    dut._log.info("Frame 1")

async def dump_frame(dut, filename):
    receiver = VgaReceiver(dut)
    image = Image.new("RGB", (800, 600))

    for y in range(600):
        for x in range(800):
            image.putpixel((x, y), receiver.decode().color())
            await RisingEdge(dut.clk)

        for n in range(40):
            v = receiver.decode()
            assert not v.hs() and not v.vs()
            await RisingEdge(dut.clk)

        for n in range(128):
            v = receiver.decode()
            assert v.hs() and not v.vs()
            await RisingEdge(dut.clk)

        for n in range(88):
            v = receiver.decode()
            assert not v.hs() and not v.vs()
            await RisingEdge(dut.clk)

    for n in range(1 * 1056):
        v = receiver.decode()
        assert not v.vs()
        await RisingEdge(dut.clk)

    for n in range(4 * 1056):
        v = receiver.decode()
        assert v.vs()
        await RisingEdge(dut.clk)

    for n in range(23 * 1056):
        v = receiver.decode()
        assert not v.vs()
        await RisingEdge(dut.clk)

    image.save(filename)

@dataclass
class VgaSymbol:
    symbol: int

    def hs(self) -> bool:
        return bool(self.symbol & 0b00000001)

    def vs(self) -> bool:
        return bool(self.symbol & 0b00000010)

    def red(self) -> int:
        return ((self.symbol >> 6) & 0x3) * 0x55

    def green(self) -> int:
        return ((self.symbol >> 4) & 0x3) * 0x55

    def blue(self) -> int:
        return ((self.symbol >> 2) & 0x3) * 0x55

    def color(self) -> tuple[int, int, int]:
        return self.red(), self.green(), self.blue()

class VgaReceiver:
    def __init__(self, dut):
        self.dut = dut

    def decode(self):
        symbol: int = 0

        # Red
        symbol |= self.dut.uo_out[0].value.integer << 7
        symbol |= self.dut.uo_out[4].value.integer << 6

        # Green
        symbol |= self.dut.uo_out[1].value.integer << 5
        symbol |= self.dut.uo_out[5].value.integer << 4

        # Blue
        symbol |= self.dut.uo_out[2].value.integer << 3
        symbol |= self.dut.uo_out[6].value.integer << 2

        # Vs, Hs
        symbol |= self.dut.uo_out[3].value.integer << 1
        symbol |= self.dut.uo_out[7].value.integer

        return VgaSymbol(symbol)
