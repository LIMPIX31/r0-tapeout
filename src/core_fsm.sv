module core_fsm
( input  logic i_clk
, input  logic i_rst
, input  logic i_btn

, output logic o_lit
, output logic o_miss
, output logic [2:0]  o_dst
, output logic [23:0] o_measured
, output logic [5:0]  o_shrnd
);

    logic        btn_d;
    logic [5:0]  sub;
    logic [26:0] cnt;
    logic [15:0] rnd;
    logic [23:0] bcd;

    logic clicked;
    logic tick;
    logic bcd_rst;

    enum logic [2:0]
    { IDLE
    , DEBOUNCE
    , WAIT
    , MEASURE
    , EARLY
    , FINISH
    } state;

    assign o_lit   = state == MEASURE;
    assign o_miss  = state == EARLY;
    assign clicked = i_btn & ~btn_d;
    assign o_shrnd = rnd[5:0];

    assign tick = sub == 6'd39;

    always_comb begin
        unique case (state)
            IDLE:           o_dst = 3'b000;
            DEBOUNCE, WAIT: o_dst = 3'b001;
            EARLY:          o_dst = 3'b011;
            FINISH:         o_dst = 3'b110;
            default:        o_dst = 3'b010;
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state      <= IDLE;
            cnt        <= 0;
            sub        <= 0;
            rnd        <= 16'hDEAD;
            btn_d      <= 0;
            bcd_rst    <= 0;
            o_measured <= {6{4'b1111}};
        end else begin
            btn_d <= i_btn;

            unique case (state)
                IDLE: begin
                    if (clicked) begin
                        state  <= DEBOUNCE;
                    end

                    rnd <= {rnd[14:0], rnd[15] ^ rnd[13] ~^ rnd[12] ^ rnd[10]};
                    cnt <= 0;
                    bcd_rst <= 1;
                end
                // Debounce button input
                DEBOUNCE: begin
                    if (cnt[19]) begin
                        state <= WAIT;
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 27'd1;
                    end
                end
                // Wait for green
                WAIT: begin
                    // Catch early hit
                    if (clicked) begin
                        state  <= EARLY;
                        cnt <= 0;
                    end else if (cnt[26:11] >= rnd) begin
                        state <= MEASURE;
                        bcd_rst <= 0;
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 27'd1;
                    end
                end
                MEASURE: begin
                    // Return to IDLE state if counter goes too high
                    if (cnt[24]) begin
                        state <= IDLE;
                    end else if (clicked) begin
                        state <= FINISH;
                        cnt <= 0;
                        o_measured <= bcd;
                    end else if (sub == 6'd39) begin
                        sub <= 0;
                        cnt <= cnt + 27'd1;
                    end else begin
                        sub <= sub + 6'd1;
                        cnt <= cnt + 27'd1;
                    end
                end
                EARLY, FINISH: begin
                    if (cnt[24]) begin
                        state <= IDLE;
                    end else begin
                        cnt <= cnt + 27'd1;
                    end
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
