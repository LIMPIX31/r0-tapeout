module layout
( input  logic [9:0]  i_x
, input  logic [9:0]  i_y
, input  logic [2:0]  i_dst
, input  logic [23:0] i_bcd
, input  logic        i_lit
, input  logic        i_miss
, input  logic        i_init

, output logic       o_bcdmux
, output logic [4:0] o_char
, output logic [1:0] o_color
);

    localparam bit [6:0] RECT_X = 20;
    localparam bit [6:0] RECT_Y = 20;
    localparam bit [6:0] LINES  = 7;
    localparam bit [6:0] LENGTH = 21;

    logic [6:0] block_x, block_y;
    logic [4:0] offset_x;
    logic [2:0] offset_y;
    logic y_active, x_active;

    logic [4:0] uninit_text [8];
    logic [4:0] bcd_text [8];

    logic [4:0] lines [LINES][LENGTH];

    assign block_x = i_x[9:3];
    assign block_y = i_y[9:3];

    assign y_active = (block_y >= RECT_Y) && (block_y < RECT_Y + LINES);
    assign x_active = (block_x >= RECT_X) && (block_x < RECT_X + LENGTH);

    assign offset_y = 3'(block_y - RECT_Y);
    assign offset_x = 5'(block_x - RECT_X);

    assign o_bcdmux = block_y[0];

    // I hate this fucking yosys System Verilog support so much
    // You just can't '{8{5'b01011}}
    always_comb begin
        if (i_init) begin
            for (int i = 0; i < 8; i++) begin
                bcd_text[i] = 5'b01011;
            end
        end else begin
            bcd_text[0] = 5'b01010;
            bcd_text[1] = {1'b0, i_bcd[23:20]};
            bcd_text[2] = {1'b0, i_bcd[19:16]};
            bcd_text[3] = {1'b0, i_bcd[15:12]};
            bcd_text[4] = 5'b01010;
            bcd_text[5] = {1'b0, i_bcd[11:8]};
            bcd_text[6] = {1'b0, i_bcd[7:4]};
            bcd_text[7] = {1'b0, i_bcd[3:0]};
        end
    end

    always_comb begin
        for (int l = 0; l < LINES; l++) begin
            for (int c = 0; c < LENGTH; c++) begin
                lines[l][c] = 5'b11111;
            end
        end

        unique case (i_dst)
            // "Press button to start"
            3'b000: lines[0] =
            { 5'b01100, 5'b01101, 5'b01110, 5'b01111, 5'b01111, 5'b11111
            , 5'b10000, 5'b10001, 5'b10010, 5'b10010, 5'b10011, 5'b10100, 5'b11111
            , 5'b10010, 5'b10011, 5'b11111
            , 5'b01111, 5'b10010, 5'b10101, 5'b01101, 5'b10010
            };
            //  "Wait"
            3'b001: lines[0][0:3] = { 5'b10110, 5'b10101, 5'b10111, 5'b10010 };
            // "#####################"
            3'b010: lines[0] =
            { 5'b01011, 5'b01011, 5'b01011, 5'b01011, 5'b01011, 5'b01011
            , 5'b01011, 5'b01011, 5'b01011, 5'b01011, 5'b01011, 5'b01011
            , 5'b01011, 5'b01011, 5'b01011, 5'b01011, 5'b01011, 5'b01011
            , 5'b01011, 5'b01011, 5'b01011
            };
            // "Miss"
            3'b011: lines[0][0:3] = { 5'b11000, 5'b10111, 5'b01111, 5'b01111 };
            // "Hit"
            3'b110: lines[0][0:2] = { 5'b11110, 5'b10111, 5'b10010 };
            default: begin end
        endcase

        // "Last: "
        lines[4][0:5]   = { 5'b11001, 5'b10101, 5'b01111, 5'b10010, 5'b11010, 5'b11111 };
        // "Best: "
        lines[5][0:5]   = { 5'b11011, 5'b01110, 5'b01111, 5'b10010, 5'b11010, 5'b11111 };
        // BCD ".000.000"
        for (int i = 0; i < 8; i++) begin
            lines[4][i+6] = bcd_text[i];
            lines[5][i+6] = bcd_text[i];
        end

        // "Last: .xxx.xxx"
        // "________ms__us"
        lines[6] = {
            // Pad (7)
            5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111,
            // Ms (3)
            5'b11111, 5'b11101, 5'b01111,
            // Us (4)
            5'b11111, 5'b11111, 5'b11100, 5'b01111,
            // Pad
            5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111
        };
    end

    assign o_char  = (y_active && x_active) ? (lines[offset_y][offset_x]) : 5'b11111;
    assign o_color = {i_miss, i_lit};

endmodule : layout
