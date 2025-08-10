/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module tt_um_limpix31_r0
( input  logic [7:0] ui_in    // Dedicated inputs
, output logic [7:0] uo_out   // Dedicated outputs
, input  logic [7:0] uio_in   // IOs: Input path
, output logic [7:0] uio_out  // IOs: Output path
, output logic [7:0] uio_oe   // IOs: Enable path (active high: 0=input, 1=output)
, input  logic       ena      // always 1 when the design is powered, so you can ignore it
, input  logic       clk      // clock
, input  logic       rst_n    // reset_n - low to reset

`ifdef VGA_DE
, output logic vga_de
`endif
);

    logic rst;

    logic btn_n;

    logic [23:0] last_result;
    logic [23:0] best_result;

    logic lit, miss;

    logic [4:0] char;
    logic [1:0] color;
    logic [2:0] display_state;
    logic [5:0] shrnd;

    logic bcd_mux;
    logic rgb_mux;

    logic [10:0] x, y;
    logic hs, vs;

    logic [1:0] r, g, b;

    io_map u_io
    ( .ena(ena)
    , .rst_n(rst_n)

    , .ui_in(ui_in)
    , .uo_out(uo_out)
    , .uio_in(uio_in)
    , .uio_out(uio_out)
    , .uio_oe(uio_oe)

    , .btn_n(btn_n)
    , .rst(rst)
    , .r(r)
    , .g(g)
    , .b(b)
    , .hs(hs)
    , .vs(vs)
    );

    core_fsm u_fsm
    ( .i_clk(clk)
    , .i_rst(rst)
    , .i_btn_n(btn_n)

    , .o_lit(lit)
    , .o_miss(miss)
    , .o_dst(display_state)
    , .o_last(last_result)
    , .o_best(best_result)
    , .o_shrnd(shrnd)
    );

    layout u_layout
    ( .i_x(x)
    , .i_y(y)
    , .i_bcd(bcd_mux ? best_result : last_result)
    , .i_lit(lit)
    , .i_miss(miss)
    , .i_init(&best_result)
    , .i_dst(display_state)

    , .o_bcdmux(bcd_mux)
    , .o_char(char)
    , .o_color(color)
    , .o_rgbmux(rgb_mux)
    );

    graphics u_graphics
    ( .i_char(char)
    , .i_color(color)
    , .i_x(x)
    , .i_y(y)
    , .i_rgb(shrnd)
    , .i_sel(rgb_mux)

    , .o_video({r, g, b})
    );

    vga_timings u_timings
    ( .clk(clk)
    , .rst(rst)

    , .x(x)
    , .y(y)
    , .hs(hs)
    , .vs(vs)

    `ifdef VGA_DE
    , .de(vga_de)
    `endif
    );

endmodule
