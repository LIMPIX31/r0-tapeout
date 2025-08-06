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
    logic [23:0] bcd;
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
    , .o_measured(result[0])
    );

    bcd_project u_bcd
    ( .bin(bcd_mux ? result[1] : result[0])
    , .bcd(bcd)
    );

    layout u_layout
    ( .i_x(x)
    , .i_y(y)
    , .i_bcd(bcd)
    , .i_lit(lit)
    , .i_miss(miss)
    , .i_init(&result[1])

    , .o_bcdmux(bcd_mux)
    , .o_char(char)
    , .o_color(color)
    );

    graphics u_graphics
    ( .i_clk(clk)
    , .i_char(char)
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

module io_map
( input  logic ena
, input  logic rst_n

, input  logic [7:0] ui_in
, output logic [7:0] uo_out
, input  logic [7:0] uio_in
, output logic [7:0] uio_out
, output logic [7:0] uio_oe

, output logic btn
, output logic rst

, input  logic [1:0] r, g, b
, input  logic hs, vs
);

    assign rst = ~rst_n;
    assign btn = ~ui_in[0];

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

module core_fsm
( input  logic i_clk
, input  logic i_rst
, input  logic i_btn
, input  logic i_fbk
, input  logic [15:0] i_rnd

, output logic o_lit
, output logic o_miss
, output logic [18:0] o_measured
);

    logic        btn_d;
    logic [4:0]  sub;
    logic [23:0] cnt;
    logic [15:0] target;

    logic clicked;
    logic bcd_rst;
    logic tick;
    logic overflow;

    enum logic [2:0]
    { IDLE
    , DEBOUNCE
    , WAIT
    , FBK
    , MEASURE
    , EARLY
    , FINISH
    } state;

    assign o_lit  = state == FBK || state == MEASURE;
    assign o_miss = state == EARLY;
    assign clicked = i_btn & ~btn_d;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state      <= IDLE;
            cnt        <= 0;
            sub        <= 0;
            target     <= 0;
            btn_d      <= 0;
            o_measured <= {19{1'b1}};
        end else begin
            btn_d <= i_btn;

            unique case (state)
                IDLE: begin
                    if (clicked) begin
                        state  <= DEBOUNCE;
                        target <= i_rnd;
                    end

                    cnt <= 0;
                end
                // Debounce button input
                DEBOUNCE: begin
                    if (&cnt[19:0]) begin
                        state <= WAIT;
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 24'd1;
                    end
                end
                // Wait for green
                WAIT: begin
                    // Catch early hit
                    if (clicked) begin
                        state  <= EARLY;
                        cnt <= 0;
                    end else if (cnt[23:8] >= target) begin
                        state <= FBK;
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 24'd1;
                    end
                end
                // Wait for feedback signal to compensate time
                FBK: begin
                    if (i_fbk) begin
                        state <= MEASURE;
                    end

                    sub <= 0;
                end
                MEASURE: begin
                    // Return to IDLE state if counter goes too high
                    if (&cnt[18:0]) begin
                        state <= IDLE;
                        cnt <= 0;
                    end else if (clicked) begin
                        state <= FINISH;
                        cnt <= 0;
                        o_measured <= cnt[18:0];
                    end else if (sub >= 5'd24) begin
                        sub <= 0;
                        cnt <= cnt + 24'd1;
                    end else begin
                        sub <= sub + 5'd1;
                    end
                end
                EARLY, FINISH: begin
                    if (&cnt) begin
                        state <= IDLE;
                    end else begin
                        cnt <= cnt + 24'd1;
                    end
                end
            endcase
        end
    end

endmodule : core_fsm

module prng
( input  logic clk
, input  logic rst

, output logic [15:0] rnd
);

    logic feedback;

    assign feedback = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10];

    always @(posedge clk) begin
        if (rst) begin
            rnd <= 0;
        end else begin
            rnd <= {rnd[14:0], feedback} | 1;
        end
    end

endmodule

module layout
( input  logic [9:0]  i_x
, input  logic [9:0]  i_y
, input  logic [23:0] i_bcd
, input  logic        i_lit
, input  logic        i_miss
, input  logic        i_init

, output logic       o_bcdmux
, output logic [4:0] o_char
, output logic [1:0] o_color
);

    logic [6:0] block_x, block_y;
    logic [3:0] offset;
    logic y_active, x_active;

    assign block_x = i_x[9:3];
    assign block_y = i_y[9:3];

    assign y_active = block_y[6:1] == 6'd10;
    assign x_active = (block_x >= 7'd20) && (block_x <= 7'd29);

    assign offset = (block_x - 7'd20);

    always_comb begin
        o_char   = 5'b11111;
        o_bcdmux = block_y[0];
        o_color  = {i_miss, i_lit};

        if (y_active && x_active) begin
            if (i_init) begin
                o_char = 5'b01011;
            end else begin
                case (offset)
                    4'd0: o_char = 5'b01010;
                    4'd1: o_char = {1'b0, i_bcd[23:20]};
                    4'd2: o_char = {1'b0, i_bcd[19:16]};
                    4'd3: o_char = {3'd0, i_bcd[15:12]};
                    4'd4: o_char = 5'b01010;
                    4'd5: o_char = {1'b0, i_bcd[11:8]};
                    4'd6: o_char = {1'b0, i_bcd[7:4]};
                    4'd7: o_char = {1'b0, i_bcd[3:0]};
                    default: o_char = 5'b11111;
                endcase
            end
        end
    end

endmodule : layout

module graphics
( input  logic       i_clk
, input  logic [4:0] i_char
, input  logic [1:0] i_color
, input  logic [9:0] i_x, i_y

, output logic [5:0] o_video
);

    logic [2:0] cx, cy;

    logic [4:0] rescii;
    logic [5:0] fg, bg;

    logic dot;

    assign cx = i_x[2:0];
    assign cy = i_y[2:0];

    assign o_video = dot ? fg : bg;

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

    bitmap_rom u_bitmap
    (i_char, cy, cx, dot);

endmodule : graphics

module bcd_project #
( parameter int unsigned W = 19
, parameter int unsigned BCD_W = W + (W - 4) / 3
)
( input  logic [W-1:0]   bin
, output logic [BCD_W:0] bcd
);

    always_comb begin
        for (int i = 0; i <= BCD_W; i++) begin
            bcd[i] = 0;
        end

        bcd[W-1:0] = bin;

        for(int i = 0; i <= W - 4; i++) begin
            for(int j = 0; j <= i / 3; j++) begin
                if (bcd[W-i+4*j -: 4] > 4) begin
                    bcd[W-i+4*j -: 4] = bcd[W-i+4*j -: 4] + 4'd3;
                end
            end
        end
    end

endmodule : bcd_project

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
, input  logic rst

, output logic hs, vs, of
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

    `ifdef VGA_DE
        logic nde;
    `endif

    assign hs = x <= H_SYNC_START || x > H_SYNC_END;
    assign vs = y <= V_SYNC_START || y > V_SYNC_END;

    always_comb begin
        of = 0;

        if (x == H_TOTAL - 1) begin
            nx = 0;

            if (y == V_TOTAL - 1) begin
                ny = 0;
                of = 1'b1;
            end else begin
                ny = y + 10'd1;
            end
        end else begin
            nx = x + 10'd1;
            ny = y;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            x  <= 0;
            y  <= 0;

            `ifdef VGA_DE
                de <= 0;
            `endif
        end else begin
            x  <= nx;
            y  <= ny;

            `ifdef VGA_DE
                de <= nx < H_ACTIVE && ny < V_ACTIVE;
            `endif
        end
    end

endmodule : vga_timings

module bitmap_rom
( input  logic [4:0] char
, input  logic [2:0] row
, input  logic [2:0] col

, output logic       dot
);

    logic [0:7] rom [96];
    logic [7:0] addr;

    logic [0:7] data;

    assign addr = {char, row};
    assign data = rom[addr];
    assign dot  = data[col];

    initial begin
        // 0
        rom[8'b00000_000] = 8'b00111000;
        rom[8'b00000_001] = 8'b01000100;
        rom[8'b00000_010] = 8'b01001100;
        rom[8'b00000_011] = 8'b01010100;
        rom[8'b00000_100] = 8'b01100100;
        rom[8'b00000_101] = 8'b01000100;
        rom[8'b00000_110] = 8'b00111000;
        rom[8'b00000_111] = 8'b00000000;
        // 1
        rom[8'b00001_000] = 8'b00010000;
        rom[8'b00001_001] = 8'b00110000;
        rom[8'b00001_010] = 8'b01010000;
        rom[8'b00001_011] = 8'b00010000;
        rom[8'b00001_100] = 8'b00010000;
        rom[8'b00001_101] = 8'b00010000;
        rom[8'b00001_110] = 8'b01111100;
        rom[8'b00001_111] = 8'b00000000;
        // 2
        rom[8'b00010_000] = 8'b00111000;
        rom[8'b00010_001] = 8'b01000100;
        rom[8'b00010_010] = 8'b00000100;
        rom[8'b00010_011] = 8'b00001000;
        rom[8'b00010_100] = 8'b00110000;
        rom[8'b00010_101] = 8'b01000000;
        rom[8'b00010_110] = 8'b01111100;
        rom[8'b00010_111] = 8'b00000000;
        // 3
        rom[8'b00011_000] = 8'b00111000;
        rom[8'b00011_001] = 8'b01000100;
        rom[8'b00011_010] = 8'b00000100;
        rom[8'b00011_011] = 8'b00011000;
        rom[8'b00011_100] = 8'b00000100;
        rom[8'b00011_101] = 8'b01000100;
        rom[8'b00011_110] = 8'b00111000;
        rom[8'b00011_111] = 8'b00000000;
        // 4
        rom[8'b00100_000] = 8'b00001000;
        rom[8'b00100_001] = 8'b00011000;
        rom[8'b00100_010] = 8'b00101000;
        rom[8'b00100_011] = 8'b01001000;
        rom[8'b00100_100] = 8'b01111100;
        rom[8'b00100_101] = 8'b00001000;
        rom[8'b00100_110] = 8'b00001000;
        rom[8'b00100_111] = 8'b00000000;
        // 5
        rom[8'b00101_000] = 8'b01111100;
        rom[8'b00101_001] = 8'b01000000;
        rom[8'b00101_010] = 8'b01111000;
        rom[8'b00101_011] = 8'b00000100;
        rom[8'b00101_100] = 8'b00000100;
        rom[8'b00101_101] = 8'b01000100;
        rom[8'b00101_110] = 8'b00111000;
        rom[8'b00101_111] = 8'b00000000;
        // 6
        rom[8'b00110_000] = 8'b00011100;
        rom[8'b00110_001] = 8'b00100000;
        rom[8'b00110_010] = 8'b01000000;
        rom[8'b00110_011] = 8'b01111000;
        rom[8'b00110_100] = 8'b01000100;
        rom[8'b00110_101] = 8'b01000100;
        rom[8'b00110_110] = 8'b00111000;
        rom[8'b00110_111] = 8'b00000000;
        // 7
        rom[8'b00111_000] = 8'b01111100;
        rom[8'b00111_001] = 8'b00000100;
        rom[8'b00111_010] = 8'b00001000;
        rom[8'b00111_011] = 8'b00010000;
        rom[8'b00111_100] = 8'b00100000;
        rom[8'b00111_101] = 8'b00100000;
        rom[8'b00111_110] = 8'b00100000;
        rom[8'b00111_111] = 8'b00000000;
        // 8
        rom[8'b01000_000] = 8'b00111000;
        rom[8'b01000_001] = 8'b01000100;
        rom[8'b01000_010] = 8'b01000100;
        rom[8'b01000_011] = 8'b00111000;
        rom[8'b01000_100] = 8'b01000100;
        rom[8'b01000_101] = 8'b01000100;
        rom[8'b01000_110] = 8'b00111000;
        rom[8'b01000_111] = 8'b00000000;
        // 9
        rom[8'b01001_000] = 8'b00111000;
        rom[8'b01001_001] = 8'b01000100;
        rom[8'b01001_010] = 8'b01000100;
        rom[8'b01001_011] = 8'b00111100;
        rom[8'b01001_100] = 8'b00000100;
        rom[8'b01001_101] = 8'b00001000;
        rom[8'b01001_110] = 8'b01110000;
        rom[8'b01001_111] = 8'b00000000;
        // .
        rom[8'b01010_000] = 8'b00000000;
        rom[8'b01010_001] = 8'b00000000;
        rom[8'b01010_010] = 8'b00000000;
        rom[8'b01010_011] = 8'b00000000;
        rom[8'b01010_100] = 8'b00000000;
        rom[8'b01010_101] = 8'b00000000;
        rom[8'b01010_110] = 8'b00010000;
        rom[8'b01010_111] = 8'b00000000;
        // unk
        rom[8'b01011_000] = 8'b00010001;
        rom[8'b01011_001] = 8'b00100010;
        rom[8'b01011_010] = 8'b01000100;
        rom[8'b01011_011] = 8'b10001000;
        rom[8'b01011_100] = 8'b00010001;
        rom[8'b01011_101] = 8'b00100010;
        rom[8'b01011_110] = 8'b01000100;
        rom[8'b01011_111] = 8'b10001000;
    end

endmodule : bitmap_rom
