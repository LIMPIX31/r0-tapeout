/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module graphics
( input  logic [4:0]  i_char
, input  logic [1:0]  i_color
, input  logic [10:0] i_x, i_y
, input  logic [5:0]  i_rgb
, input  logic        i_sel

, output logic [5:0]  o_video
);

    logic [2:0] cx, cy;
    logic [5:0] fg, bg;
    logic [15:0] _unused;

    logic dot;

    assign cx = i_x[2:0];
    assign cy = i_y[2:0];

    assign _unused = {i_x[10:3], i_y[10:3]};

    always_comb begin
        if (i_sel) begin
            o_video = i_rgb;
        end else if (dot) begin
            o_video = fg;
        end else begin
            o_video = bg;
        end
    end

    always_comb begin
        unique case(i_color)
            2'b00: begin
                fg = 6'b111111;
                bg = 6'b000000;
            end
            2'b01: begin
                fg = 6'b000000;
                bg = 6'b011101;
            end
            2'b10: begin
                fg = 6'b000000;
                bg = 6'b110001;
            end
            2'b11: begin
                fg = 6'b000000;
                bg = 6'b000000;
            end
        endcase
    end

    bitmap_rom #(5) u_bitmap
    (i_char, cy, cx, dot);

endmodule : graphics
