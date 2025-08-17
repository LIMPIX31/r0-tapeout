/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module layout
( input  logic [10:0] i_x
, input  logic [10:0] i_y
, input  logic [2:0]  i_dst
, input  logic [23:0] i_bcd
, input  logic        i_lit
, input  logic        i_miss
, input  logic        i_init

, output logic        o_bcdmux
, output logic [4:0]  o_char
, output logic [1:0]  o_color
, output logic        o_rgbmux
);

    localparam bit [7:0] RECT_X = 20;
    localparam bit [7:0] RECT_Y = 20;
    localparam bit [7:0] LINES  = 10;
    localparam bit [7:0] LENGTH = 14;

    logic [7:0] block_x, block_y;
    logic [3:0] offset_x;
    logic [3:0] offset_y;
    logic y_active, x_active;

    logic [4:0] bcd_text [8];

    logic [5:0] _unused;

    assign block_x = i_x[10:3];
    assign block_y = i_y[10:3];

    assign y_active = (block_y >= RECT_Y) && (block_y < RECT_Y + LINES);
    assign x_active = (block_x >= RECT_X) && (block_x < RECT_X + LENGTH);

    assign offset_y = 4'(block_y - RECT_Y);
    assign offset_x = 4'(block_x - RECT_X);

    assign o_bcdmux = block_y[0];

    assign _unused = {i_x[2:0], i_y[2:0]};

    always_comb begin
        if (i_init) begin
            for (int i = 0; i < 8; i++) begin
                bcd_text[i] = 5'b11101;
            end
        end else begin
            bcd_text[0] = 5'b01010;
            bcd_text[1] = {1'd0, i_bcd[23:20]};
            bcd_text[2] = {1'd0, i_bcd[19:16]};
            bcd_text[3] = {1'd0, i_bcd[15:12]};
            bcd_text[4] = 5'b01010;
            bcd_text[5] = {1'd0, i_bcd[11:8]};
            bcd_text[6] = {1'd0, i_bcd[7:4]};
            bcd_text[7] = {1'd0, i_bcd[3:0]};
        end
    end

    always_comb begin
        if (y_active && x_active) begin
            case (offset_y)
                0: // Line 0
                    case (i_dst)
                        3'b000: // "Press button to start"
                            case (offset_x)
                                0:  o_char = 5'b10000; // P
                                1:  o_char = 5'b11000; // r
                                2:  o_char = 5'b10100; // e
                                3:  o_char = 5'b11001; // s
                                4:  o_char = 5'b11001; // s
                                5:  o_char = 5'b11111; //
                                6:  o_char = 5'b11010; // t
                                7:  o_char = 5'b10111; // o
                                8:  o_char = 5'b11111; //
                                9:  o_char = 5'b11001; // s
                                10: o_char = 5'b11010; // t
                                11: o_char = 5'b10010; // a
                                12: o_char = 5'b11000; // r
                                13: o_char = 5'b11010; // t
                                default: o_char = 5'b11111;
                            endcase
                        3'b001: // "Ready"
                            case (offset_x)
                                0: o_char = 5'b10001; // R
                                1: o_char = 5'b10100; // e
                                2: o_char = 5'b10010; // a
                                3: o_char = 5'b10011; // d
                                4: o_char = 5'b11011; // y
                                default: o_char = 5'b11111;
                            endcase
                        3'b010: // "#####################"
                            o_char = 5'b11101;
                        3'b011: // "Miss"
                            case (offset_x)
                                0: o_char = 5'b01111; // M
                                1: o_char = 5'b10101; // i
                                2: o_char = 5'b11001; // s
                                3: o_char = 5'b11001; // s
                                default: o_char = 5'b11111;
                            endcase
                        3'b110: // "Hit"
                            case (offset_x)
                                0: o_char = 5'b01101; // H
                                1: o_char = 5'b10101; // i
                                2: o_char = 5'b11010; // t
                                default: o_char = 5'b11111;
                            endcase
                        default: o_char = 5'b11111;
                    endcase
                4: // Line 4: "Last: .xxx.xxx"
                    case (offset_x)
                        0: o_char = 5'b01110; // L
                        1: o_char = 5'b10010; // a
                        2: o_char = 5'b11001; // s
                        3: o_char = 5'b11010; // t
                        4: o_char = 5'b01011; // :
                        default: if (offset_x >= 6) begin
                            o_char = bcd_text[offset_x - 6];
                        end else begin
                            o_char = 5'b11111;
                        end
                    endcase
                5: // Line 5: "Best: .xxx.xxx"
                    case (offset_x)
                        0: o_char = 5'b01100; // B
                        1: o_char = 5'b10100; // e
                        2: o_char = 5'b11001; // s
                        3: o_char = 5'b11010; // t
                        4: o_char = 5'b01011; // :
                        default: if (offset_x >= 6) begin
                            o_char = bcd_text[offset_x - 6];
                        end else begin
                            o_char = 5'b11111;
                        end
                    endcase
                6: // Line 6: "________ms__us"
                    case (offset_x)
                        8:  o_char = 5'b10110; // m
                        9:  o_char = 5'b11001; // s
                        12: o_char = 5'b11100; // u
                        13: o_char = 5'b11001; // s
                        default: o_char = 5'b11111;
                    endcase
                default: o_char = 5'b11111; // Empty lines
            endcase
        end else begin
            o_char = 5'b11111; // Passive region
        end
    end

    assign o_color  = {i_miss, i_lit};
    assign o_rgbmux = block_x == 20 && block_y == 29;

endmodule : layout
