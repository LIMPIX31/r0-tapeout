/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module io_map
( input  logic ena
, input  logic rst_n

, input  logic [7:0] ui_in
, output logic [7:0] uo_out
, input  logic [7:0] uio_in
, output logic [7:0] uio_out
, output logic [7:0] uio_oe

, output logic btn_n
, output logic rst

, input  logic [1:0] r, g, b
, input  logic hs, vs
);

    assign rst   = ~rst_n;
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
