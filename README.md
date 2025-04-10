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
vlog -quiet  -work ${LIB_PATH} ${RTL_PATH}/components/ST_SPHDL_2048x8m8_L.v                  || goto error ----add this line\

vlog -quiet -sv -work ${LIB_PATH} +incdir+${RTL_PATH}/includes ${ASIC_DEFINES} ${CORE_DEFINES} ${RTL_PATH}/**pulpino_top_pads**.sv        || goto error\

~/ICP1/etin35_project/pulpino/vsim/vcompile/rtl/vcompile_tb.sh\
vlog -quiet -sv -work ${LIB_NAME} +incdir+${TB_PATH} +incdir+${RTL_PATH}/includes/                  ${TB_PATH}/**tb_pads**.sv               || goto error\
vlog -quiet -sv -work ${LIB_NAME} +incdir+${TB_PATH} +incdir+${RTL_PATH}/includes/ -dpiheader ${TB_PATH}/mem_dpi/dpiheader.h    ${TB_PATH}/**tb_pads**.sv || goto error

----Modification for pads

--------------------------

# Simulation operations:
## 1. Add/Change signals in wave.do
if reports like:\
//# ** Error: (vish-4014) No objects found matching '/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[0]/u_sram/D'.\
change signals in wave.do:\
//add wave -noupdate -radix hexadecimal {/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/sp_ram_i} ---- for old wrapper\
~//ram_block[0]/u_sram/D ----- for new warpper

--------------------------
## 2. Once a rtl file is changed, in modelsim:
find in library using the binoculars -> recompile -> restart sim

--------------------------
Synthesis
These folders need to exist in the main project directory along side rtl.
• Copy genus folder and genus.sh to main project folder

• Open terminal in GENUS project folder

• From there run genus and source the script:

        ./genus.sh
        Source GENUS/scripts/synt.tcl  

To Do:

• One of the RAM library files must be changed to the correct one. Currently it is set to the library file for ram belonging to matrix multiplier.
 
• I’m not sure if the other library files are the same as the matrix multiplication or not but in either case I have kept all library files except for RAM the same. 
 
• Also I have not changed the clock constraints and they are the same ones as for matrix multiplication. I am not sure if we have new constraints. 
 
![image](https://github.com/user-attachments/assets/801a3d8c-4460-4db9-b50f-9242c498be53)



