module bcd_counter #
( parameter int unsigned DIGITS = 6
)
( input logic clk
, input logic rst
, input logic count

, output logic [DIGITS*4-1:0] bcd
);

    logic [DIGITS:0] carry;
    logic _overflow;

    assign carry[0] = count;
    assign _overflow = carry[DIGITS];

    generate
        for (genvar i = 0; i < DIGITS; i++) begin
            bcd_unit u_bcd
            ( .clk(clk)
            , .rst(rst)
            , .count(carry[i])
            , .digit(bcd[i*4 +: 4])
            , .carry(carry[i + 1])
            );
        end
    endgenerate

endmodule : bcd_counter

module bcd_unit
( input logic clk
, input logic rst
, input logic count

, output logic [3:0] digit
, output logic carry
);

    assign carry = (digit[3] & digit[0]) & count;

    always_ff @(posedge clk) begin
        if (rst) begin
            digit <= 0;
        end else if (count) begin
            if (digit == 4'd9) begin
                digit <= 0;
            end else begin
                digit <= digit + 4'd1;
            end
        end else begin
            digit <= digit;
        end
    end

endmodule : bcd_unit
