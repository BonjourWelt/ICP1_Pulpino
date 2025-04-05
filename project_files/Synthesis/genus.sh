#!/bin/bash

# Source the setup file
# . inittde dicp23
# if it didnt work do it manually like this:
#source /usr/local-eit/cad2/cmpstm/stm065v536/setup2023.efd


# commands to run tools

#----------------------------------------
# vsim &

#----------------------------------------
. inittde dicp23
genus -legacy_ui

# after we are in genus shell we can simply source the script file this way
# source DIRECTORY/script.tcl
# where DIRECTORY is directory relative to current working directory  

# source GENUS/scripts/synt.tcl 

# redirect log file using genus shell because legacy mode
# genus

#----------------------------------------
# . inittde dicp23
# innovus

#----------------------------------------
# power analysis
# inittde dicp21
# primetime
