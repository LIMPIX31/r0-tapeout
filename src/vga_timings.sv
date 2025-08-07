module vga_timings #
( parameter bit [9:0] H_TOTAL = 800
, parameter bit [9:0] H_ACTIVE = 640
, parameter bit [9:0] V_TOTAL = 525
, parameter bit [9:0] V_ACTIVE = 480
, parameter bit [9:0] H_FRONT_PORCH = 16
, parameter bit [9:0] H_SYNC = 96
, parameter bit [9:0] V_FRONT_PORCH = 10
, parameter bit [9:0] V_SYNC = 2
)
( input  logic clk
, input  logic rst

, output logic hs, vs, of
, output logic [9:0] x, y

`ifdef VGA_DE
, output logic de
`endif
);

    localparam bit [9:0] H_SYNC_START = 10'(H_ACTIVE + H_FRONT_PORCH);
    localparam bit [9:0] H_SYNC_END   = 10'(H_SYNC_START + H_SYNC);
    localparam bit [9:0] V_SYNC_START = 10'(V_ACTIVE + V_FRONT_PORCH);
    localparam bit [9:0] V_SYNC_END   = 10'(V_SYNC_START + V_SYNC);

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
