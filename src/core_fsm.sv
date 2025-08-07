module core_fsm
( input  logic i_clk
, input  logic i_rst
, input  logic i_btn
, input  logic i_fbk
, input  logic [15:0] i_rnd

, output logic o_lit
, output logic o_miss
, output logic [2:0]  o_dst
, output logic [18:0] o_measured
);

    logic        btn_d;
    logic [4:0]  sub;
    logic [23:0] cnt;
    logic [15:0] target;

    logic clicked;

    enum logic [2:0]
    { IDLE
    , DEBOUNCE
    , WAIT
    , FBK
    , MEASURE
    , EARLY
    , FINISH
    } state;

    assign o_lit   = state == FBK || state == MEASURE;
    assign o_miss  = state == EARLY;
    assign clicked = i_btn & ~btn_d;

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
