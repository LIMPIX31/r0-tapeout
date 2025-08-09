module layout
( input  logic [10:0] i_x
, input  logic [10:0] i_y
, input  logic [2:0]  i_dst
, input  logic [23:0] i_bcd
, input  logic        i_lit
, input  logic        i_miss
, input  logic        i_init

, output logic        o_bcdmux
, output logic [5:0]  o_char
, output logic [1:0]  o_color
, output logic        o_rgbmux
);

    localparam bit [7:0] RECT_X = 20;
    localparam bit [7:0] RECT_Y = 20;
    localparam bit [7:0] LINES  = 10;
    localparam bit [7:0] LENGTH = 21;

    logic [7:0] block_x, block_y;
    logic [4:0] offset_x;
    logic [3:0] offset_y;
    logic y_active, x_active;

    logic [5:0] bcd_text [8];

    logic [5:0] _unused;

    assign block_x = i_x[10:3];
    assign block_y = i_y[10:3];

    assign y_active = (block_y >= RECT_Y) && (block_y < RECT_Y + LINES);
    assign x_active = (block_x >= RECT_X) && (block_x < RECT_X + LENGTH);

    assign offset_y = 4'(block_y - RECT_Y);
    assign offset_x = 5'(block_x - RECT_X);

    assign o_bcdmux = block_y[0];

    assign _unused = {i_x[2:0], i_y[2:0]};

    always_comb begin
        if (i_init) begin
            for (int i = 0; i < 8; i++) begin
                bcd_text[i] = 6'b100000; // Dash
            end
        end else begin
            bcd_text[0] = 6'b001010; // Dot
            bcd_text[1] = {2'd0, i_bcd[23:20]};
            bcd_text[2] = {2'd0, i_bcd[19:16]};
            bcd_text[3] = {2'd0, i_bcd[15:12]};
            bcd_text[4] = 6'b001010; // Dot
            bcd_text[5] = {2'd0, i_bcd[11:8]};
            bcd_text[6] = {2'd0, i_bcd[7:4]};
            bcd_text[7] = {2'd0, i_bcd[3:0]};
        end
    end

    always_comb begin
        if (y_active && x_active) begin
            case (offset_y)
                4'd0: // Line 0: Status line
                    case (i_dst)
                        3'b000: // "Press button to start"
                            case (offset_x)
                                5'd0:  o_char = 6'b010000; // P
                                5'd1:  o_char = 6'b011010; // r
                                5'd2:  o_char = 6'b010101; // e
                                5'd3:  o_char = 6'b011011; // s
                                5'd4:  o_char = 6'b011011; // s
                                5'd5:  o_char = 6'b111111; //
                                5'd6:  o_char = 6'b010011; // b
                                5'd7:  o_char = 6'b011101; // u
                                5'd8:  o_char = 6'b011100; // t
                                5'd9:  o_char = 6'b011100; // t
                                5'd10: o_char = 6'b011001; // o
                                5'd11: o_char = 6'b011000; // n
                                5'd12: o_char = 6'b111111; //
                                5'd13: o_char = 6'b011100; // t
                                5'd14: o_char = 6'b011001; // o
                                5'd15: o_char = 6'b111111; //
                                5'd16: o_char = 6'b011011; // s
                                5'd17: o_char = 6'b011100; // t
                                5'd18: o_char = 6'b010010; // a
                                5'd19: o_char = 6'b011010; // r
                                5'd20: o_char = 6'b011100; // t
                                default: o_char = 6'b111111;
                            endcase
                        3'b001: // "Ready"
                            case (offset_x)
                                5'd0: o_char = 6'b010001; // R
                                5'd1: o_char = 6'b010101; // e
                                5'd2: o_char = 6'b010010; // a
                                5'd3: o_char = 6'b010100; // d
                                5'd4: o_char = 6'b011110; // y
                                default: o_char = 6'b111111;
                            endcase
                        3'b010: // "#####################"
                            o_char = (offset_x < 21) ? 6'b100000 : 6'b111111;
                        3'b011: // "Miss"
                            case (offset_x)
                                5'd0: o_char = 6'b001111; // M
                                5'd1: o_char = 6'b010110; // i
                                5'd2: o_char = 6'b011011; // s
                                5'd3: o_char = 6'b011011; // s
                                default: o_char = 6'b111111;
                            endcase
                        3'b110: // "Hit"
                            case (offset_x)
                                5'd0: o_char = 6'b001101; // H
                                5'd1: o_char = 6'b010110; // i
                                5'd2: o_char = 6'b011100; // t
                                default: o_char = 6'b111111;
                            endcase
                        default: o_char = 6'b111111; // Other i_dst
                    endcase
                4'd4: // Line 4: "Last: .xxx.xxx"
                    case (offset_x)
                        5'd0: o_char = 6'b001110; // L
                        5'd1: o_char = 6'b010010; // a
                        5'd2: o_char = 6'b011011; // s
                        5'd3: o_char = 6'b011100; // t
                        5'd4: o_char = 6'b001011; // :
                        5'd5: o_char = 6'b111111; //
                        default: if (offset_x >= 6 && offset_x < 14) begin
                            o_char = bcd_text[offset_x - 6];
                        end else begin
                            o_char = 6'b111111;
                        end
                    endcase
                4'd5: // Line 5: "Best: .xxx.xxx"
                    case (offset_x)
                        5'd0: o_char = 6'b001100; // B
                        5'd1: o_char = 6'b010101; // e
                        5'd2: o_char = 6'b011011; // s
                        5'd3: o_char = 6'b011100; // t
                        5'd4: o_char = 6'b001011; // :
                        5'd5: o_char = 6'b111111; //
                        default: if (offset_x >= 6 && offset_x < 14) begin
                            o_char = bcd_text[offset_x - 6];
                        end else begin
                            o_char = 6'b111111;
                        end
                    endcase
                4'd6: // Line 6: "________ms__us"
                    case (offset_x)
                        5'd8:  o_char = 6'b010111; // m
                        5'd9:  o_char = 6'b011011; // s
                        5'd12: o_char = 6'b011111; // u
                        5'd13: o_char = 6'b011011; // s
                        default: o_char = 6'b111111;
                    endcase
                default: o_char = 6'b111111; // Empty lines
            endcase
        end else begin
            o_char = 6'b111111; // Passive region
        end
    end

    assign o_color  = {i_miss, i_lit};
    assign o_rgbmux = x_active && y_active && offset_y == 9;

endmodule : layout
