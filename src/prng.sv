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

endmodule : prng
