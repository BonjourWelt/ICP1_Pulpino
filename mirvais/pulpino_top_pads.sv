module pulpino_top_pads (
    input [13:0] INP,
    output [10:0] UTP,
    input clk,
    input spi_clk,
    input jtag_clk
);

    // Internal signals
    wire [13:0] INPi;
    wire [10:0] UTPi;
    wire clki;
    wire spi_clki;
    wire jtag_clki;
    wire HIGH, LOW;

    // Constants
    assign HIGH = 1'b1;
    assign LOW  = 1'b0;

    // Input PADs
    genvar i;
    generate
        for (i = 0; i < 14; i = i + 1) begin : InPads
            CPAD_S_74x50u_IN InPad (
                .COREIO(INPi[i]),
                .PADIO(INP[i])
            );
        end
    endgenerate

    // SPI Clock Pad
    CPAD_S_74x50u_IN spi_clk_pad (
        .COREIO(spi_clki),
        .PADIO(spi_clk)
    );

    // JTAG Clock Pad
    CPAD_S_74x50u_IN jtag_clk_pad (
        .COREIO(jtag_clki),
        .PADIO(jtag_clk)
    );

    // Clock Pad
    CPAD_S_74x50u_IN clkpad (
        .COREIO(clki),
        .PADIO(clk)
    );

    // Output PADs
    generate
        for (i = 0; i < 11; i = i + 1) begin : OutPads
            CPAD_S_74x50u_OUT OutPad (
                .COREIO(UTPi[i]),
                .PADIO(UTP[i])
            );
        end
    endgenerate

    // Instantiation of the pulpino_top component
    pulpino_top pulpino_top_i (
        .clk(clki),
        .rst_n(INPi[0]),
        //.testmode_i(INPi[1]), tied test mode to ground this frees up a pad
        .testmode_i(1'b0),
        .fetch_enable_i(INPi[2]),
        .spi_clk_i(spi_clki),
        .spi_cs_i(INPi[3]),
        .spi_mode_o(UTPi[1:0]),
        .spi_sdo0_o(UTPi[2]),
        .spi_sdo1_o(UTPi[3]),
        .spi_sdo2_o(UTPi[4]),
        .spi_sdo3_o(UTPi[5]),
        .spi_sdi0_i(INPi[4]),
        .spi_sdi1_i(INPi[5]),
        .spi_sdi2_i(INPi[6]),
        .spi_sdi3_i(INPi[7]),
        .uart_tx(UTPi[6]),
        .uart_rx(INPi[8]),
        .uart_rts(UTPi[7]),
        .uart_dtr(UTPi[8]),
        .uart_cts(INPi[9]),
        .uart_dsr(INPi[10]),
        .gpio_out8(UTPi[9]),
        .tck_i(jtag_clki),
        .trstn_i(INPi[11]),
        .tms_i(INPi[12]),
        .tdi_i(INPi[13]),
        .tdo_o(UTPi[10])
    );

endmodule
