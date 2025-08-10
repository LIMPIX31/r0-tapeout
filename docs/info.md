<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

It's a lightweight version of the original [r0](https://github.com/LIMPIX31/r0) project, optimized for a smaller area on
ASIC.

**r0** lets you measure human reaction time really accurately interfacing only VGA compatible monitor and a single
button. The precision is 1 microsecond.

The state is not synchronized with vsync, so the monitor may display only a few green lines before you react, which
gives you flexibility in your response. It also forces you to watch the entire monitor, not just the upper left corner,
waiting for the first green pixel.

## How to test

1. Connect your monitor to Tiny VGA and the button (with pull-up resistor) to `ui[0]`.
2. Make sure that the lower LFSR debug line looks like noise in the idle state.
3. Press the button once to get ready.
4. and as soon as you see green on the monitor, press the button as quickly as possible.
5. Check the results of your reaction speed 
6. Try press earlier, the screen will turn red, which means that your reaction was false.

## External hardware

* Tiny VGA
* Pulled-up button to `ui[0]`
