`define VGA_DE

module top
( input  logic i_rst_n
, input  logic i_clk_50m

, input  logic i_btn_n

, output logic       o_hdmi_clk_p
, output logic       o_hdmi_clk_n
, output logic [2:0] o_hdmi_chan_p
, output logic [2:0] o_hdmi_chan_n
);

    logic pll_lock;
    logic hdmi_pclk, hdmi_sclk;

    logic hs, vs, de;
    logic rm, gm, bm, rl, gl, bl;
    logic [23:0] video;

    logic [2:0][9:0] chan_vec;

    assign video = {{4{rm, rl}}, {4{gm, gl}}, {4{bm, bl}}};

    tt_um_limpix31_r0 u_dut
    ( .clk(hdmi_pclk)
    , .ui_in({7'd0, i_btn_n})
    , .uo_out({hs, bl, gl, rl, vs, bm, gm, rm})
    , .uio_in(8'd0)
    , .uio_out()
    , .uio_oe()

    , .ena(1'b1)
    , .rst_n(i_rst_n)

    , .vga_de(de)
    );

    hclk u_hclk
    ( .i_clk_50m(i_clk_50m)
    , .o_lock(pll_lock)
    , .o_pclk(hdmi_pclk)
    , .o_sclk(hdmi_sclk)
    );

    hvtx_mod u_mod
    ( .i_pclk(hdmi_pclk)
    , .i_sclk(hdmi_sclk)
    , .i_hs(hs)
    , .i_vs(vs)
    , .i_de(de)
    , .i_video(video)
    , .o_chan_vec(chan_vec)
    );

    hvtx_ser u_ser
    ( .i_pclk(hdmi_pclk)
    , .i_sclk(hdmi_sclk)
    , .i_rst(~i_rst_n)
    , .i_chan_vec(chan_vec)
    , .o_hdmi_clk_p(o_hdmi_clk_p)
    , .o_hdmi_clk_n(o_hdmi_clk_n)
    , .o_hdmi_chan_p(o_hdmi_chan_p)
    , .o_hdmi_chan_n(o_hdmi_chan_n)
    );

endmodule : top
