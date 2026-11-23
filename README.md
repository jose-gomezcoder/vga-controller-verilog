# VGA Controller in Verilog

A 640x480 @ 60 Hz VGA timing generator and test-pattern generator in synthesizable Verilog, with a self-checking testbench and a Basys 3 top level that drives the board's 12-bit VGA port.

## Features

- **Parameterized timing generator:** visible area, front porch, sync and back porch can be set separately for each axis
- **Clocking:** 25 MHz pixel enable derived from the 100 MHz board clock, so the design has a single clock domain
- **Four test patterns,** selected with `sw[1:0]`:

  | `sw` | Pattern |
  |------|---------|
  | 00   | Eight colour bars: white, yellow, cyan, green, magenta, red, blue, black |
  | 01   | 32x32 checkerboard |
  | 10   | Colour gradient |
  | 11   | 32-pixel grid with a white border |

- **Aligned outputs:** colour and sync are registered together, so they reach the VGA DAC in the same cycle
- **Synchronized switches:** the switch inputs pass through a 2-flop synchronizer
- **Self-checking testbench:**
  - verifies a full frame's timing: 800 x 525 clocks, hsync and vsync pulse widths and positions, and the visible pixel count
  - spot-checks the pattern colours
  - prints PASS or FAIL

## Timing (640x480 @ 60 Hz)

|            | Visible | Front porch | Sync | Back porch | Total |
|------------|---------|-------------|------|------------|-------|
| Horizontal | 640     | 16          | 96   | 48         | 800 px |
| Vertical   | 480     | 10          | 2    | 33         | 525 lines |

Both sync pulses are active low. The standard pixel clock is 25.175 MHz. 25 MHz is close enough for monitors to lock.

## Repository layout

```
rtl/
  vga_sync.v         horizontal/vertical counters and sync generation
  pattern_gen.v      test-pattern generator (12-bit RGB)
  vga_top.v          Basys 3 top level
tb/
  tb_vga.v           self-checking testbench
constraints/
  basys3.xdc         pin constraints for Basys 3 (Artix-7)
Makefile             Icarus Verilog simulation
```

## Block diagram

```
 clk 100 MHz --> [ /4 ] --pix_en--> +----------+  x, y, video_on  +-------------+
                                    | vga_sync |----------------->| pattern_gen |--rgb--+
 sw[1:0] --> [2FF sync] ----------->|          |                  +-------------+       |
                                    +----------+--hsync/vsync----------------------+    |
                                                                                   v    v
                                                                            [output registers]
                                                                                   |
                                                              Hsync, Vsync, vgaRed/Green/Blue
```

## Simulate

You need [Icarus Verilog](https://steveicarus.github.io/iverilog/), and optionally GTKWave.

```bash
make sim     # compile and run the testbench
make wave    # open tb_vga.vcd in GTKWave
```

## Run on a Basys 3

1. Create a Vivado project for part `xc7a35tcpg236-1`.
2. Add the files in `rtl/` as design sources and `constraints/basys3.xdc` as a constraint.
3. Set `vga_top` as the top module, then generate the bitstream and program the board.
4. Connect a VGA monitor and use `sw[1:0]` to switch between patterns. `btnC` resets the design.
