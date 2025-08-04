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

    logic [9:0] x, y;
    logic hs, vs;

    logic i_btn_n;

    logic [1:0] o_r, o_g, o_b;
    logic o_hs, o_vs;

    io_map u_io
    ( .ena(ena)

    , .ui_in(ui_in)
    , .uo_out(uo_out)
    , .uio_in(uio_in)
    , .uio_out(uio_out)
    , .uio_oe(uio_oe)

    , .btn_n(i_btn_n)
    , .r(o_r)
    , .g(o_g)
    , .b(o_b)
    , .hs(o_hs)
    , .vs(o_vs)
    );

    vga_timings u_timings
    ( .clk(clk)
    , .rst_n(rst_n)

    , .x(x)
    , .y(y)
    , .hs(hs)
    , .vs(vs)

    `ifdef VGA_DE
    , .de(vga_de)
    `endif
    );

    always_comb begin
        if (y[3] ^ x[3]) begin
            {o_r, o_g, o_b} = 6'b000000;
        end else begin
            {o_r, o_g, o_b} = 6'b101110;
        end

        o_hs = hs;
        o_vs = vs;
    end

endmodule

module io_map
( input  logic ena

, input  logic [7:0] ui_in
, output logic [7:0] uo_out
, input  logic [7:0] uio_in
, output logic [7:0] uio_out
, output logic [7:0] uio_oe

, output logic btn_n

, input  logic [1:0] r, g, b
, input  logic hs, vs
);

    assign btn_n = ui_in[0];

    assign uo_out[2:0] = {b[1], g[1], r[1]};
    assign uo_out[6:4] = {b[0], g[0], r[0]};
    assign uo_out[3]   = vs;
    assign uo_out[7]   = hs;

    // Assign unused to 0.
    assign uio_out = 0;
    assign uio_oe  = 0;

     // List all unused inputs to prevent warnings
    logic _unused;

    assign _unused = &{ena, uio_in, ui_in[7:1], 1'b0};

endmodule : io_map

module vga_timings #
( parameter int unsigned H_TOTAL = 800
, parameter int unsigned H_ACTIVE = 640
, parameter int unsigned V_TOTAL = 525
, parameter int unsigned V_ACTIVE = 480
, parameter int unsigned H_FRONT_PORCH = 16
, parameter int unsigned H_SYNC = 96
, parameter int unsigned V_FRONT_PORCH = 10
, parameter int unsigned V_SYNC = 2
)
( input  logic clk
, input  logic rst_n

, output logic hs, vs
, output logic [9:0] x, y

`ifdef VGA_DE
, output logic de
`endif
);

    localparam int unsigned H_SYNC_START = H_ACTIVE + H_FRONT_PORCH;
    localparam int unsigned H_SYNC_END   = H_SYNC_START + H_SYNC;
    localparam int unsigned V_SYNC_START = V_ACTIVE + V_FRONT_PORCH;
    localparam int unsigned V_SYNC_END   = V_SYNC_START + V_SYNC;

    logic [9:0] nx, ny;
    logic nhs, nvs;

    `ifdef VGA_DE
        logic nde;
    `endif

    always_comb begin
        if (x == H_TOTAL - 1) begin
            nx = 0;

            if (y == V_TOTAL - 1) begin
                ny = 0;
            end else begin
                ny = y + 10'd1;
            end
        end else begin
            nx = x + 10'd1;
            ny = y;
        end

        nhs = x <= H_SYNC_START || x > H_SYNC_END;
        nvs = y <= V_SYNC_START || y > V_SYNC_END;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            x  <= 0;
            y  <= 0;
            hs <= 0;
            vs <= 0;

            `ifdef VGA_DE
                de <= 0;
            `endif
        end else begin
            x  <= nx;
            y  <= ny;
            hs <= nhs;
            vs <= nvs;

            `ifdef VGA_DE
                de <= nx < H_ACTIVE && ny < V_ACTIVE;
            `endif
        end
    end

endmodule : vga_timings
