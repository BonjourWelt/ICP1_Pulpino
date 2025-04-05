# what are our clock constraints?

# values are in picosecond

set PERIOD 10000
set ClkTop $DESIGN
set ClkDomain $DESIGN
# DESIGN = pulpino_top_pads
set ClkName clk_in
set ClkLatency 500
set ClkRise_uncertainty 200
set ClkFall_uncertainty 200
set ClkSlew 500
set InputDelay 500
set OutputDelay 500

# Change -port ClkxC* to the actual name of clock port/pin in your design
define_clock -name $ClkName -period $PERIOD -design $ClkTop -domain $ClkDomain [find / -port clk_in*]

set_attribute clock_network_late_latency $ClkLatency $ClkName
set_attribute clock_source_late_latency  $ClkLatency $ClkName 

set_attribute clock_setup_uncertainty $ClkLatency $ClkName
set_attribute clock_hold_uncertainty $ClkLatency $ClkName 

set_attribute slew_rise $ClkRise_uncertainty $ClkName 
set_attribute slew_fall $ClkFall_uncertainty $ClkName
 
external_delay -input $InputDelay  -clock [find / -clock $ClkName] -name in_con  [find /des* -port ports_in/*]
external_delay -output $OutputDelay -clock [find / -clock $ClkName] -name out_con [find /des* -port ports_out/*]
