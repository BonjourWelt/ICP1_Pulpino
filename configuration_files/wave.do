onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/clk
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/en_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/addr_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/wdata_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/rdata_o
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/we_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/be_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/clk
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/rstn_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/en_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/addr_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/wdata_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/rdata_o
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/we_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/be_i
add wave -noupdate -radix hexadecimal /tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/bypass_en_i
add wave -noupdate -radix hexadecimal {/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[0]/u_sram/D}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[15]/u_sram/CSN}	
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[14]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[13]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[12]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[11]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[10]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[9]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[8]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[7]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[6]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[5]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[4]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[3]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[2]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[1]/u_sram/CSN}
add wave -position end  {sim:/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[0]/u_sram/CSN}

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20530181 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {20476296 ps} {20730327 ps}
