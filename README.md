Pulpino files see [here: ](https://github.com/pulp-platform/pulpino)

# Configuration files changes:   
## 1. Disabled line in tb.sv
  `include "tb_spi_pkg.sv"\
//  `include "tb_mem_pkg.sv" --disabled in tb.sv\
  `include "spi_debug_test.svh"\
  `include "mem_dpi.svh"

  --------------------------

## 2. Added line  in compile file
~/ICP1/etin35_project/pulpino/vsim/vcompile/rtl/vcompile_pulpino.sh\
\# components\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/cluster_clock_gating.sv    || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/pulp_clock_gating.sv       || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/cluster_clock_inverter.sv  || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/cluster_clock_mux2.sv      || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/pulp_clock_inverter.sv     || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/pulp_clock_mux2.sv         || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/generic_fifo.sv            || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/rstgen.sv                  || goto error\
vlog -quiet -sv -work ${LIB_PATH} ${RTL_PATH}/components/sp_ram.sv                  || goto error\
vlog -quiet  -work ${LIB_PATH} ${RTL_PATH}/components/ST_SPHDL_2048x8m8_L.v                  || goto error ----add this line

---------

# Simulation operations:
## 1. Add/Change signals in wave.do
if reports like:\
//# ** Error: (vish-4014) No objects found matching '/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[0]/u_sram/D'.\
change signals in wave.do:\
//add wave -noupdate -radix hexadecimal {/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/sp_ram_i} ---- for old wrapper\
~//ram_block[0]/u_sram/D ----- for new warpper

------------

## 2. Once a rtl file is changed, in modelsim:
find in library using the binoculars -> recompile -> restart sim

--------------------------
