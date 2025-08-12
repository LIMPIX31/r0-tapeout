![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout R0

Ultra-precise human reaction meter

- [Read the documentation for project](docs/info.md)

![image](assets/screenshot.png)

## Why this project is so cool for learning

* **Design complexity**: VGA, FSM, PRNG, Timers, Buttons, BCD counter and Bitmap Font introduce more fun in a design
  process.
* **Area-focused optimizations**: In FPGA, you mainly perform optimizations related to timing requirements, but in ASIC,
  it is more important to keep the area of the design small.
* **Fun and Curiosity**: It is interesting to measure the speed of your own reaction and be sure that the input is not
  delayed by the CPU and the timer does not fail.

## Run Demo
Make sure [verilator](https://verilator.org/guide/latest/) and [SDL3](https://wiki.libsdl.org/SDL3/FrontPage) are installed.
The button is mapped to the space bar.
> [!WARNING]
> Demo speeds up timers to compensate low frame rate
```bash
cd demo
cmake -B build
cmake --build build -j
./build/tt_r0
```

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog
designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.
