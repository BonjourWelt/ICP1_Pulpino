#!/bin/tcsh

# Post-Synthesis Build script

if (! $?VSIM_PATH ) then
  setenv VSIM_PATH      `pwd`
endif

if (! $?PULP_PATH ) then
  setenv PULP_PATH      `pwd`/../
endif

setenv MSIM_LIBS_PATH ${VSIM_PATH}/modelsim_libs

setenv IPS_PATH       ${PULP_PATH}/ips
setenv RTL_PATH       ${PULP_PATH}/rtl
setenv TB_PATH        ${PULP_PATH}/tb

set LIB_NAME="pulpino_lib"
set LIB_PATH="${MSIM_LIBS_PATH}/${LIB_NAME}"



clear
source ${PULP_PATH}/vsim/vcompile/colors.csh

rm -rf modelsim_libs
vlib modelsim_libs

rm -rf work
vlib work

rm -rf $LIB_PATH
vlib $LIB_PATH
vmap $LIB_NAME $LIB_PATH

echo ""
echo "${Purple}--> Compiling process & sram & lu_pads libraries... ${NC}"
echo ""

# build ST and LU libraries
source ${PULP_PATH}/vsim/vcompile/vcompile_libs.csh  || exit 1
echo "${Blue}--> Process & sram & lu_pads libraries compilation complete! ${NC}"

echo ""
echo "${Purple}--> Compiling Synthesized pulp_PnR.v ... ${NC}"
echo ""

# build the synthesized top file
vlog -quiet -work $LIB_PATH ${PULP_PATH}/rtl/pulp_PnR.v || exit 1
#vlog -quiet -work $LIB_PATH ${PULP_PATH}/rtl/top_top_pnr2.v  || exit 1
echo "${Blue}--> Synthesized pulp_PnR.v compilation complete! ${NC}"

# build the testbench files
source ${PULP_PATH}/vsim/vcompile/rtl/vcompile_tb.sh  || exit 1

echo ""
echo "${Yellow}--> Compiling IP List... ${NC}"
echo ""

source ${PULP_PATH}/vsim/vcompile/vcompile_ips.csh  || exit 1

echo ""
echo "${Green}--> IP List compilation complete! ${NC}"
echo ""

echo ""
echo "${Purple}--> Synthesized PULPino platform compilation complete! ${NC}"
echo ""

