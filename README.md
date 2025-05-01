Meeting recordings:
2025/03/21
Amendments to the manual: 
    Chapter 3: 8096*32 -> 8192*32;
    Appendix 2 directory tree: SPHD110420.v/ SPHD110420.verilog.map -> SPHDL100909.v/ SPHDL100909.verilog.map.
Missions:
    Read rtl files of pulpino modules from top to bottom, find which file we are editing in order to include our sram. 
    dp_ram: duo-port ram. sp_ram: single-port ram. The rams to be replaced are "sp_ram".

2025/03/28 



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
# Synthesis
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

--------------------
## 4.25 records
1. Set clocks asychronous: set_clock_groups -asynchronous -group $ClkName1  -group $ClkName2 -group $ClkName3.
2. How to find commands using cadence help:  /usr/local-eit/cad2/cadence/gen161/bin/cdnshelp.
3. Here is a black_box in sp_wram_wrapper, the sections used for FPGA and ASIC should be commented.
4. Report black_box problem in genus: add this command in design_setup.tcl: set_attribute hdl_error_on_blackbox true /
------------------
## 4.28 records
1. When run memory test, we have to change GCC_MARCH="IM" in cmake_configure.riscv.gcc.sh. And delete the whole build folder then rebuild it.
2. If "make vcompile" fails, try exiting the terminal and re-run all steps from start.





