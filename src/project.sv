/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module tt_um_r0
( input  logic [7:0] ui_in    // Dedicated inputs
, output logic [7:0] uo_out   // Dedicated outputs
, input  logic [7:0] uio_in   // IOs: Input path
, output logic [7:0] uio_out  // IOs: Output path
, output logic [7:0] uio_oe   // IOs: Enable path (active high: 0=input, 1=output)
, input  logic       ena      // always 1 when the design is powered, so you can ignore it
, input  logic       clk      // clock
, input  logic       rst_n     // reset_n - low to reset

`ifdef VGA_DE
, output logic vga_de
`endif
);

    logic rst;

    logic btn;

    logic [15:0] rnd;
    logic [18:0] result [2];
    logic lit, miss;

    logic [4:0]  char;
    logic [1:0]  color;
    logic [24:0] bcd;
    logic [2:0]  display_state;
    logic bcd_mux;

    logic [9:0] x, y;
    logic hs, vs, of;

    logic [1:0] o_r, o_g, o_b;
    logic o_hs, o_vs;

    always_ff @(posedge clk) begin
        if (rst) begin
            result[1] <= {19{1'b1}};
        end else if (result[0] < result[1]) begin
            result[1] <= result[0];
        end else begin
            result[1] <= result[1];
        end
    end

    io_map u_io
    ( .ena(ena)
    , .rst_n(rst_n)

    , .ui_in(ui_in)
    , .uo_out(uo_out)
    , .uio_in(uio_in)
    , .uio_out(uio_out)
    , .uio_oe(uio_oe)

    , .btn(btn)
    , .rst(rst)
    , .r(o_r)
    , .g(o_g)
    , .b(o_b)
    , .hs(o_hs)
    , .vs(o_vs)
    );

    prng u_rng (clk, rst, rnd);

    core_fsm u_fsm
    ( .i_clk(clk)
    , .i_rst(rst)
    , .i_btn(btn)
    , .i_fbk(1'b1)
    , .i_rnd(rnd)

    , .o_lit(lit)
    , .o_miss(miss)
    , .o_dst(display_state)
    , .o_measured(result[0])
    );

    bcd_project u_bcd
    ( .bin(bcd_mux ? result[1] : result[0])
    , .bcd(bcd)
    );

    layout u_layout
    ( .i_x(x)
    , .i_y(y)
    , .i_bcd(bcd[23:0])
    , .i_lit(lit)
    , .i_miss(miss)
    , .i_init(&result[1])
    , .i_dst(display_state)

    , .o_bcdmux(bcd_mux)
    , .o_char(char)
    , .o_color(color)
    );

    graphics u_graphics
    ( .i_char(char)
    , .i_color(color)
    , .i_x(x)
    , .i_y(y)

    , .o_video({o_r, o_g, o_b})
    );

    vga_timings u_timings
    ( .clk(clk)
    , .rst(rst)

    , .x(x)
    , .y(y)
    , .hs(hs)
    , .vs(vs)
    , .of(of)

    `ifdef VGA_DE
    , .de(vga_de)
    `endif
    );

    always_comb begin
        o_hs = hs;
        o_vs = vs;
    end

endmodule
