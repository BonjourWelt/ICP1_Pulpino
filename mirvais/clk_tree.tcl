

#------now that the library files have been added synthesize the tree
#---the actual commands where these:
#---create_ccopt_clock_tree_spec -file ./ccopt.spec
#---source ./ccopt.spec
#---ccopt_design

#################################################################################
#################################################################################
#################################################################################
#################################################################################

# Use ccopt to generate the spec

create_ccopt_clock_tree_spec -file ./ccopt.spec
ccopt_check_and_flatten_ilms_no_restore


create_ccopt_clock_tree -name clk_in -source clk_in -no_skew_group
set_ccopt_property target_max_trans_sdc -delay_corner SS -late -clock_tree clk_in 0.200
set_ccopt_property source_latency -delay_corner SS -late -rise -clock_tree clk_in 0.500
set_ccopt_property source_latency -delay_corner SS -late -fall -clock_tree clk_in 0.500
set_ccopt_property source_latency -delay_corner FF -late -rise -clock_tree clk_in 0.500
set_ccopt_property source_latency -delay_corner FF -late -fall -clock_tree clk_in 0.500
set_ccopt_property clock_period -pin clk_in 10
create_ccopt_skew_group -name clk_in/Clock_Constraint -sources clk_in -auto_sinks
set_ccopt_property include_source_latency -skew_group clk_in/Clock_Constraint true
set_ccopt_property extracted_from_clock_name -skew_group clk_in/Clock_Constraint clk_in
set_ccopt_property extracted_from_constraint_mode_name -skew_group clk_in/Clock_Constraint Clock_Constraint
set_ccopt_property extracted_from_delay_corners -skew_group clk_in/Clock_Constraint {SS FF}





#################################################################################
#################################################################################
#################################################################################
#################################################################################


# -------------------------------
# MAIN CLOCK: clk
# -------------------------------
create_ccopt_clock_tree -name clk -source clk -no_skew_group

# Latency and transition targets
set_ccopt_property target_max_trans_sdc -delay_corner SS -late -clock_tree clk 0.200
foreach corner {SS FF} {
    foreach dir {rise fall} {
        set_ccopt_property source_latency -delay_corner $corner -late -$dir -clock_tree clk 0.500
    }
}
set_ccopt_property clock_period -pin clk 10

# Skew group for clk
create_ccopt_skew_group -name clk/Clock_Constraint -sources clk -auto_sinks
set_ccopt_property include_source_latency -skew_group clk/Clock_Constraint true
set_ccopt_property extracted_from_clock_name -skew_group clk/Clock_Constraint clk
set_ccopt_property extracted_from_constraint_mode_name -skew_group clk/Clock_Constraint Clock_Constraint
set_ccopt_property extracted_from_delay_corners -skew_group clk/Clock_Constraint {SS FF}

# -------------------------------
# SPI CLOCK: spi_clk
# -------------------------------
create_ccopt_clock_tree -name spi_clk -source spi_clk -no_skew_group
set_ccopt_property target_max_trans_sdc -delay_corner SS -late -clock_tree spi_clk 0.200
foreach corner {SS FF} {
    foreach dir {rise fall} {
        set_ccopt_property source_latency -delay_corner $corner -late -$dir -clock_tree spi_clk 0.500
    }
}
set_ccopt_property clock_period -pin spi_clk 20  ;# Example period: 50 MHz

create_ccopt_skew_group -name spi_clk/Clock_Constraint -sources spi_clk -auto_sinks
set_ccopt_property include_source_latency -skew_group spi_clk/Clock_Constraint true
set_ccopt_property extracted_from_clock_name -skew_group spi_clk/Clock_Constraint spi_clk
set_ccopt_property extracted_from_constraint_mode_name -skew_group spi_clk/Clock_Constraint Clock_Constraint
set_ccopt_property extracted_from_delay_corners -skew_group spi_clk/Clock_Constraint {SS FF}

# -------------------------------
# JTAG CLOCK: jtag_clk
# -------------------------------
create_ccopt_clock_tree -name jtag_clk -source jtag_clk -no_skew_group
set_ccopt_property target_max_trans_sdc -delay_corner SS -late -clock_tree jtag_clk 0.200
foreach corner {SS FF} {
    foreach dir {rise fall} {
        set_ccopt_property source_latency -delay_corner $corner -late -$dir -clock_tree jtag_clk 0.500
    }
}
set_ccopt_property clock_period -pin jtag_clk 100  ;# Example: 10 MHz

create_ccopt_skew_group -name jtag_clk/Clock_Constraint -sources jtag_clk -auto_sinks
set_ccopt_property include_source_latency -skew_group jtag_clk/Clock_Constraint true
set_ccopt_property extracted_from_clock_name -skew_group jtag_clk/Clock_Constraint jtag_clk
set_ccopt_property extracted_from_constraint_mode_name -skew_group jtag_clk/Clock_Constraint Clock_Constraint
set_ccopt_property extracted_from_delay_corners -skew_group jtag_clk/Clock_Constraint {SS FF}

#################################################################################
#################################################################################
#################################################################################
#################################################################################

# -------------------------------
# Final checks and launch
# -------------------------------

check_ccopt_clock_tree_convergence
get_ccopt_property auto_design_state_for_ilms
ccopt_design

