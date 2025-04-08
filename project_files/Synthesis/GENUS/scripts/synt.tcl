
#ROOT will be the project directory and folder GENUS has to be there
set ROOT "../"

set SYNT_SCRIPT    "${ROOT}/GENUS/scripts"
set SYNT_OUT       "${ROOT}/GENUS/outputs"
set SYNT_REPORT    "${ROOT}/GENUS/reports"

if {![file exists ${SYNT_SCRIPT}]}     { file mkdir ${SYNT_SCRIPT}}
if {![file exists ${SYNT_OUT}]}        { file mkdir ${SYNT_OUT}}
if {![file exists ${SYNT_REPORT}]}     { file mkdir ${SYNT_REPORT}}

#-----------------------------------------------------------------

# print 
puts "\n\n\n DESIGN FILES \n\n\n"
# execute design_setup script which defines some variables used below.
source $SYNT_SCRIPT/design_setup.tcl

#-----------------------------------------------------------------

puts "\n\n\n ANALYZE HDL DESIGN \n\n\n"
# var DESIGN_FILES= HDL file names
read_hdl -sv ${DESIGN_FILES}

#-----------------------------------------------------------------

# DESIGN is defined = top_entity so this elaborates top_entity
puts "\n\n\n ELABORATE \n\n\n"
elaborate ${DESIGN}

#-----------------------------------------------------------------
check_design
report timing -lint
#-----------------------------------------------------------------

# call the clk script
puts "\n\n\n TIMING CONSTRAINTS \n\n\n"
source $SYNT_SCRIPT/create_clock.tcl

#-----------------------------------------------------------------

#the next 3 are not defined anywhere so I assume they are commands to the tool
puts "\n\n\n SYN_GENERIC \n\n\n"
syn_generic

puts "\n\n\n SYN_MAP \n\n\n"
syn_map

puts "\n\n\n SYN_OPT \n\n\n"
syn_opt

#-----------------------------------------------------------------

puts "\n\n\n EXPORT DESIGN \n\n\n"
write_hdl    > ${SYNT_OUT}/${DESIGN}.v
write_sdc    > ${SYNT_OUT}/${DESIGN}.sdc
write_sdf   -version 2.1  > ${SYNT_OUT}/${DESIGN}.sdf

#-----------------------------------------------------------------

puts "\n\n\n REPORTING \n\n\n"
report qor      > $SYNT_REPORT/qor_${DESIGN}.rpt
report area     > $SYNT_REPORT/area_${DESIGN}.rpt
report datapath > $SYNT_REPORT/datapath_${DESIGN}.rpt
report messages > $SYNT_REPORT/messages_${DESIGN}.rpt
report gates    > $SYNT_REPORT/gates_${DESIGN}.rpt
report timing   > $SYNT_REPORT/timing_${DESIGN}.rpt
report timing -lint > $SYNT_REPORT/timing_lint_${DESIGN}.rpt
