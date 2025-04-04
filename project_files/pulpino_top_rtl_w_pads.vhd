library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pulpino_top_rtl_w_pads is
  port(
    INP : in std_logic_vector(13 downto 0);
    UTP : out std_logic_vector(10 downto 0);
    clk : in std_logic;
    spi_clk : in std_logic;
    jtag_clk : in std_logic
    );
end pulpino_top_rtl_w_pads;


architecture STRUCTURAL of pulpino_top_rtl_w_pads is

  component CPAD_S_74x50u_IN            --input PAD

    port (
      COREIO : out std_logic;
      PADIO  : in  std_logic
	 );
  end component;

  component CPAD_S_74x50u_OUT           --output PAD
    port (
      COREIO : in  std_logic;
      PADIO  : out std_logic
	 );
  end component;

  component pulpino_top
    port (
	  clk : in std_logic;
	  rst_n : in std_logic;

	  testmode_i : in std_logic;
	  fetch_enable_i : in std_logic;

	  spi_clk_i : in std_logic;
	  spi_cs_i : in std_logic;
	  spi_mode_o : out std_logic_vector(1 downto 0);
	  spi_sdo0_o : out std_logic;
	  spi_sdo1_o : out std_logic;
	  spi_sdo2_o : out std_logic;
	  spi_sdo3_o : out std_logic;
	  spi_sdi0_i : in std_logic;
	  spi_sdi1_i : in std_logic;
	  spi_sdi2_i : in std_logic;
	  spi_sdi3_i : in std_logic;

      uart_tx : out std_logic;
      uart_rx : in std_logic;
	  uart_rts : out std_logic;
	  uart_dtr : out std_logic;
	  uart_cts : in std_logic;
	  uart_dsr : in std_logic;

	  gpio_out8 : out std_logic;

	  tck_i : in std_logic;
	  trstn_i : in std_logic;
	  tms_i : in std_logic;
	  tdi_i : in std_logic;
	  tdo_o : out std_logic
	 );
end component;

  signal INPi	: std_logic_vector(13 downto 0);
  signal UTPi	: std_logic_vector(10 downto 0);
  signal clki   : std_logic;
  signal spi_clki : std_logic;
  signal jtag_clki : std_logic;

  signal HIGH, LOW : std_logic;

begin

  HIGH <= '1';
  LOW  <= '0';

  InPads : for i in 0 to 13 generate
    InPad : CPAD_S_74x50u_IN
      port map (COREIO => INPi(i),
        	PADIO  => INP(i)
	        );
  end generate InPads;

  spi_clk_pad : CPAD_S_74x50u_IN
    port map (COREIO => spi_clki,
              PADIO => spi_clk 
              );

  jtag_clk_pad : CPAD_S_74x50u_IN
    port map (COREIO => jtag_clki,
              PADIO => jtag_clk
              );

  clkpad : CPAD_S_74x50u_IN
    port map (COREIO => clki,
      	      PADIO  => clk
	      );

  OutPads : for i in 0 to 10 generate
    OutPad : CPAD_S_74x50u_OUT
      port map (COREIO => UTPi(i),
        	PADIO  => UTP(i)
		);
  end generate OutPads;

  pulpino_top_rtl_inst : pulpino_top
  port map (
		clk => clki,
		rst_n => INPi(0),
		testmode_i => INPi(1),
	    fetch_enable_i => INPi(2),
	    spi_clk_i => spi_clki,
	    spi_cs_i  => INPi(3),
	    spi_mode_o => UTPi(1 downto 0),
	    spi_sdo0_o => UTPi(2),
	    spi_sdo1_o => UTPi(3),
	    spi_sdo2_o => UTPi(4),
	    spi_sdo3_o => UTPi(5),
	    spi_sdi0_i => INPi(4),
	    spi_sdi1_i => INPi(5),
	    spi_sdi2_i => INPi(6),
	    spi_sdi3_i => INPi(7),
    	uart_tx => UTPi(6),
    	uart_rx => INPi(8),
	    uart_rts => UTPi(7),
	    uart_dtr => UTPi(8),
	    uart_cts => INPi(9),
	    uart_dsr => INPi(10),
	    gpio_out8 => UTPi(9),
	    tck_i => jtag_clki,
	    trstn_i => INPi(11),
	    tms_i => INPi(12),
	    tdi_i => INPi(13),
	    tdo_o => UTPi(10)
	   );

end STRUCTURAL;




