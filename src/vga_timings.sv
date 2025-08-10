/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module vga_timings #
( parameter bit [10:0] H_TOTAL = 1056
, parameter bit [10:0] H_ACTIVE = 800
, parameter bit [10:0] V_TOTAL = 628
, parameter bit [10:0] V_ACTIVE = 600
, parameter bit [10:0] H_FRONT_PORCH = 40
, parameter bit [10:0] H_SYNC = 128
, parameter bit [10:0] V_FRONT_PORCH = 1
, parameter bit [10:0] V_SYNC = 4
)
( input  logic clk
, input  logic rst

, output logic hs, vs
, output logic [10:0] x, y

`ifdef VGA_DE
, output logic de
`endif
);

    localparam bit [10:0] H_SYNC_START = 11'(H_ACTIVE + H_FRONT_PORCH);
    localparam bit [10:0] H_SYNC_END   = 11'(H_SYNC_START + H_SYNC);
    localparam bit [10:0] V_SYNC_START = 11'(V_ACTIVE + V_FRONT_PORCH);
    localparam bit [10:0] V_SYNC_END   = 11'(V_SYNC_START + V_SYNC);

    `ifdef VGA_DE
        assign de = x < H_ACTIVE && y < V_ACTIVE;
    `endif

    assign hs = x >= H_SYNC_START && x < H_SYNC_END;
    assign vs = y >= V_SYNC_START && y < V_SYNC_END;

    always_ff @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else if (x == H_TOTAL - 1) begin
            x <= 0;
            y <= (y == V_TOTAL - 1) ? 11'd0 : y + 11'd1;
        end else begin
            x <= x + 11'd1;
        end
    end

endmodule : vga_timings
