# ------------------------------------------------------------------------------
# Genus Synthesis Setup Script for PULPino ASIC Design
# ------------------------------------------------------------------------------

# Top module name
set DESIGN pulpino_top_pads

# RTL root path
set RTL "$ROOT/rtl"
set COMPONENTS "$RTL/components"
set INCLUDES "$RTL/includes"

# ------------------------------------------------------------------------------
# Script and HDL search paths
# ------------------------------------------------------------------------------

#search for scripts here
set_attribute script_search_path $SYNT_SCRIPT

#search for HDL files here
set_attribute init_hdl_search_path "$RTL $COMPONENTS $INCLUDES"

# ------------------------------------------------------------------------------
# Technology library paths (library search path for RAM, pads, clock cells, etc.)
# ------------------------------------------------------------------------------

set_attribute init_lib_search_path {
  /usr/local-eit/cad2/cmpstm/stm065v536/CORE65LPLVT_5.1/libs
  /usr/local-eit/cad2/cmpstm/stm065v536/CLOCK65LPLVT_3.1/libs
  Usr/local-eit/cad2/cpstm/oldmems/mem2010/SPHDL100909-40446@1.0/libs
  /usr/local-eit/cad2/cmpstm/dicp18/lu_pads_65nm
}
# RAM for matrix_mult if needed
# /usr/local-eit/cad2/cmpstm/oldmems/mem2011/SPHD110420-48158@1.0/libs

# ------------------------------------------------------------------------------
# Liberty (.lib) files for synthesis
# ------------------------------------------------------------------------------

# more libraries related files (corner conditions?)
set_attribute library { \
CLOCK65LPLVT_nom_1.20V_25C.lib \
CORE65LPLVT_nom_1.20V_25C.lib \
SPHD110420_nom_1.20V_25C.lib \
Pads_Oct2012.lib} /

# CHANGE:
# RAM isnt the corrent

# ------------------------------------------------------------------------------
# RTL Source Files (SystemVerilog)
# ------------------------------------------------------------------------------

set DESIGN_FILES "
  $RTL/pulpino_top_pads.sv
  $RTL/apb_mock_uart.sv
  $RTL/axi_mem_if_SP_wrap.sv
  $RTL/axi_node_intf_wrap.sv
  $RTL/axi_slice_wrap.sv
  $RTL/axi_spi_slave_wrap.sv
  $RTL/axi2apb_wrap.sv
  $RTL/boot_code.sv
  $RTL/boot_rom_wrap.sv
  $RTL/clk_rst_gen.sv
  $RTL/core_region.sv
  $RTL/core2axi_wrap.sv
  $RTL/dp_ram_wrap.sv
  $RTL/instr_ram_wrap.sv
  $RTL/periph_bus_wrap.sv
  $RTL/peripherals.sv
  $RTL/pulpino_top.sv
  $RTL/ram_mux.sv
  $RTL/random_stalls.sv
  $RTL/sp_ram_wrap.sv

  $COMPONENTS/cluster_clock_gating.sv
  $COMPONENTS/cluster_clock_inverter.sv
  $COMPONENTS/cluster_clock_mux2.sv
  $COMPONENTS/dp_ram.sv
  $COMPONENTS/generic_fifo.sv
  $COMPONENTS/pulp_clock_gating.sv
  $COMPONENTS/pulp_clock_inverter.sv
  $COMPONENTS/pulp_clock_mux2.sv
  $COMPONENTS/rstgen.sv
  $COMPONENTS/sp_ram.sv

  $INCLUDES/apb_bus.sv
  $INCLUDES/apu_defines.sv
  $INCLUDES/axi_bus.sv
  $INCLUDES/config.sv
  $INCLUDES/debug_bus.sv
"
# ------------------------------------------------------------------------------
# Synthesis Effort Settings
# ------------------------------------------------------------------------------

set SYN_EFF high
set MAP_EFF high
set OPT_EFF high

set_attribute syn_generic_effort $SYN_EFF
set_attribute syn_map_effort $MAP_EFF
set_attribute syn_opt_effort $OPT_EFF
set_attribute information_level 5 ;# Set to 1–9 for verbosity
# change to lower number for less info