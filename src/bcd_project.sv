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
