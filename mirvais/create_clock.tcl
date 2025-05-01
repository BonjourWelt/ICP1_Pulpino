

set ClkTop $DESIGN


set ClkDomain_i $DESIGN
set ClkName1 clk
set PERIOD_i 10000
set ClkLatency_i 500
set ClkRise_uncertainty_i 200
set ClkFall_uncertainty_i 200
set ClkSlew_i 500
set InputDelay_i 500
set OutputDelay_i 500

# Change -port ClkxC* to the actual name of clock port/pin in your design
define_clock -name $ClkName1 -period $PERIOD_i -design $ClkTop -domain $ClkDomain_i [find / -port clk*]
external_delay -input $InputDelay_i  -clock [find / -clock $ClkName1] -name in_con  [find /des* -port ports_in/*]
external_delay -output $OutputDelay_i -clock [find / -clock $ClkName1] -name out_con [find /des* -port ports_out/*]

set_attribute clock_network_late_latency $ClkLatency_i $ClkName1
set_attribute clock_source_late_latency  $ClkLatency_i $ClkName1 

set_attribute clock_setup_uncertainty $ClkLatency_i $ClkName1
set_attribute clock_hold_uncertainty $ClkLatency_i $ClkName1 

set_attribute slew_rise $ClkRise_uncertainty_i $ClkName1 
set_attribute slew_fall $ClkFall_uncertainty_i $ClkName1

#-------------------------------------------------------------------

set PERIOD_spi 10000
set ClkDomain_SPI SPI
set ClkName2 spi_clk
set ClkLatency_spi  500
set ClkRise_uncertainty_spi 200
set ClkFall_uncertainty_spi 200
set ClkSlew_spi 500
set InputDelay_spi 500
set OutputDelay_spi 500

define_clock -name $ClkName2 -period $PERIOD_spi -design $ClkTop -domain $ClkDomain_SPI [find / -port spi_clk*]
external_delay -input $InputDelay_spi  -clock [find / -clock $ClkName2] -name in_con  [find /des* -port ports_in/*]
external_delay -output $OutputDelay_spi -clock [find / -clock $ClkName2] -name out_con [find /des* -port ports_out/*]

set_attribute clock_network_late_latency $ClkLatency_spi $ClkName2
set_attribute clock_source_late_latency  $ClkLatency_spi $ClkName2 

set_attribute clock_setup_uncertainty $ClkLatency_spi $ClkName2
set_attribute clock_hold_uncertainty $ClkLatency_spi $ClkName2 

set_attribute slew_rise $ClkRise_uncertainty_spi $ClkName2 
set_attribute slew_fall $ClkFall_uncertainty_spi $ClkName2

#-------------------------------------------------------------------

set PERIOD_jtag 10000
set ClkDomain_JTAG JTAG
set ClkName3 jtag_clk
set ClkLatency_jtag  500
set ClkRise_uncertainty_jtag 200
set ClkFall_uncertainty_jtag 200
set ClkSlew_jtag 500
set InputDelay_jtag 500
set OutputDelay_jtag 500

define_clock -name $ClkName3 -period $PERIOD_jtag -design $ClkTop -domain $ClkDomain_JTAG [find / -port jtag_clk*]
external_delay -input $InputDelay_jtag  -clock [find / -clock $ClkName3] -name in_con  [find /des* -port ports_in/*]
external_delay -output $OutputDelay_jtag -clock [find / -clock $ClkName3] -name out_con [find /des* -port ports_out/*]

set_attribute clock_network_late_latency $ClkLatency_jtag $ClkName3
set_attribute clock_source_late_latency  $ClkLatency_jtag $ClkName3 

set_attribute clock_setup_uncertainty $ClkLatency_jtag $ClkName3
set_attribute clock_hold_uncertainty $ClkLatency_jtag $ClkName3 

set_attribute slew_rise $ClkRise_uncertainty_jtag $ClkName3 
set_attribute slew_fall $ClkFall_uncertainty_jtag $ClkName3
#-------------------------------------------------------------------

set_clock_groups -asynchronous -group $ClkName1 -group $ClkName2 -group $ClkName3
