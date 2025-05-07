####----------------------------------------------------------####
# Title        : primeTime Sample Script
# Project      : IC Project 1
####----------------------------------------------------------####
# File         : ptime.tcl
# Module Name  : 
# Project Root : 
# Author       : Masoud Nouripayam (ma1570no@eit.lth.se)
# Company      : Digital ASIC Group, EIT, LTH, Lund University
# Created      : 2020-03-02
# Last Edit    : 
# version      : 1
####----------------------------------------------------------####
# Description  : 
####----------------------------------------------------------####

##################  remove any previous designs 
remove_design -all


################### set up power analysis mode #####################
# step 0: Define Top Module name 
set TOP YOUR_TOP_MODULE_NAME

################### set up power analysis mode #####################
# step 1: enalbe analysis mode 
set power_enable_analysis  true
set power_analysis_mode time_based

####################### set up libaries ############################
# step 2: link to your design libary 

### Make sure you choose the same files and paths as you have used in
### synthesis and pnr stage

set search_path "\
/usr/local-eit/cad2/cmpstm/mem2011/SPHD110420-48158@1.0/libs \
/usr/local-eit/cad2/cmpstm/stm065v536/CORE65LPLVT_5.1/libs \
/usr/local-eit/cad2/cmpstm/stm065v536/CLOCK65LPLVT_3.1/libs \
/usr/local-eit/cad2/cmpstm/stm065v536/IO65LPHVT_SF_1V8_50A_7M4X0Y2Z_7.0/libs \
/usr/local-eit/cad2/cmpstm/stm065v536/IO65LP_SF_BASIC_50A_ST_7M4X0Y2Z_7.2/libs"

set link_path   "* \
MEMORY_TIMING_FILE.db \
CORE_TIMING_FILE.db \
CLOCK_TIMING_FILE.db \
IO_TIMING_FILE.db"

####################### design input    ############################
# step 3: read your design (netlist) & link design
read_verilog /PATH_TO_YOUR_NETLIST/YOUR_PNR_NETLIST.v
current_design $TOP
link_design -force

####################### timing constraint ##########################
# step 4: setup timing constraint (or read sdc file)
read_sdc /PATH_TO_SDC/YOUR_PNR_SDC.sdc

####################### Back annotate     ##########################
# step 5: back annotate delay information (read sdf file)
read_parasitics /PATH_TO_SPEF/YOUR_PNR_SPEF_PARASITICS.spef
read_sdf -type sdf_max /PATH_TO_SDF/YOUR_PNR_SDF.sdf

################# read switching activity file #####################
# step 6: read vcd file obtained from post-layout (syn) simulation
read_vcd -strip_path "/[string tolower medianfilter_tb/dut]" /PATH_TO_VCD/YOUR_VCD_FILE.vcd

####################### analysis and report #################
# step 7: Analysis the power
check_power
update_power

####################### report  #################
# step 8: output report
report_power -verbose > /PATH_TO_YOUR_REPORT/power.rpt
report_timing -delay_type min -max_paths 10 > /PATH_TO_YOUR_REPORT/timing_hold.rpt
report_timing -delay_type max -max_paths 10 > /PATH_TO_YOUR_REPORTS/timing_setup.rpt
