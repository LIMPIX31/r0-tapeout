/*
 * Copyright (c) 2025 Danil Karpenko
 * SPDX-License-Identifier: Apache-2.0
 */

module core_fsm
( input  logic i_clk
, input  logic i_rst
, input  logic i_btn_n

, output logic o_lit
, output logic o_miss
, output logic [2:0]  o_dst
, output logic [23:0] o_last
, output logic [23:0] o_best
, output logic [5:0]  o_shrnd
);

	// The demo runs slower, so I speed up the timers
	`ifdef DEMO
		localparam int unsigned TIMER_SETUP   = 18;
		localparam int unsigned TIMER_GUARD   = 22;
		localparam int unsigned TIMER_TIMEOUT = 22;
		localparam int unsigned RND_DIV       = 3;
	`else
		localparam int unsigned TIMER_SETUP   = 22;
		localparam int unsigned TIMER_GUARD   = 26;
		localparam int unsigned TIMER_TIMEOUT = 25;
		// (!) RND_DIV must be 0 if not running demo
		localparam int unsigned RND_DIV       = 0;
	`endif

    logic [5:0]  sub;
    logic [26:0] cnt;
    logic [15:0] rnd;
    logic [23:0] bcd;

    logic btn_d0, btn_d1, btn;

    logic clicked;
    logic tick;
    logic bcd_rst;

    enum logic [2:0]
    { IDLE
    , SETUP
    , GUARD
    , WAIT
    , MEASURE
    , EARLY
    , FINISH
    } state;

    assign o_lit   = state == MEASURE;
    assign o_miss  = state == EARLY;
    assign clicked = btn & ~btn_d1;
    assign o_shrnd = rnd[5:0];

    assign bcd_rst = state != MEASURE;
    assign tick    = sub == 6'd39;

    always_comb begin
        unique case (state)
            IDLE, SETUP: o_dst = 3'b000;
            GUARD, WAIT: o_dst = 3'b001;
            EARLY:       o_dst = 3'b011;
            FINISH:      o_dst = 3'b110;
            default:     o_dst = 3'b010;
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            // Reset state and counters
            state  <= IDLE;
            cnt    <= 0;
            sub    <= 0;

            // Random init seed
            rnd    <= 16'hDEAD;

            // Reset button sync
            btn_d0 <= 0;
            btn_d1 <= 0;
            btn    <= 0;

            // Reset results
            o_last <= {6{4'b1111}};
            o_best <= {6{4'b1111}};
        end else begin
            btn_d0 <= i_btn_n;
            btn_d1 <= btn_d0;
            btn    <= btn_d1;

            unique case (state)
                IDLE: begin
                    if (clicked) begin
                        state <= SETUP;
                    end

                    // Run LFSR during IDLE
                    rnd <= {rnd[14:0], rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10]};
                end
                // Debounce button
                SETUP: if (cnt[TIMER_SETUP]) begin
                    state <= GUARD;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 27'd1;
                end
                // Wait a moment for the user to focus
                GUARD: if (clicked) begin
                    state <= EARLY;
                    cnt <= 0;
                end else if (cnt[TIMER_GUARD]) begin
                    state <= WAIT;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 27'd1;
                end
                // Wait for green and handle false input
                WAIT: if (clicked) begin
                    state <= EARLY;
                    cnt <= 0;
                end else if (cnt == {rnd, 11'd0} >> RND_DIV) begin
                    state <= MEASURE;
                    sub <= 0;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 27'd1;
                end
                // Enable the BCD counter until the button is pressed 
                // or the timeout expires.
                MEASURE: if (clicked) begin
                    state <= FINISH;
                    cnt <= 0;

                    // Store last/best results
                    o_last <= bcd;

                    if (bcd < o_best) begin
                        o_best <= bcd;
                    end
                // Check for timeout
                end else if (cnt[TIMER_TIMEOUT]) begin
                    state <= IDLE;
                    cnt <= 0;
                // Every time the sub counter reaches 39, 1us passes
                end else if (sub == 6'd39) begin
                    sub <= 0;
                    cnt <= cnt + 27'd1;
                end else begin
                    sub <= sub + 6'd1;
                    cnt <= cnt + 27'd1;
                end
                // Ignore any input data for some time after
                // a successful measurement or miss
                EARLY, FINISH: if (cnt[TIMER_TIMEOUT]) begin
                    state <= IDLE;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 27'd1;
                end
            endcase
        end
    end

    bcd_counter #(6) u_counter
    ( .clk(i_clk)
    , .rst(bcd_rst)
    , .count(tick)
    , .bcd(bcd)
    );

endmodule : core_fsm
