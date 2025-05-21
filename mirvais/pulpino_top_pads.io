version: 1

# # ------------------------------------------------ #
# # Corner pads
# # Format: Pad: name position technology
# # ------------------------------------------------ #
Orient: R270
Pad: PcornerLL SW PADSPACE_C_74x74u_CH
Orient: R0x3
Pad: PcornerLR SE PADSPACE_C_74x74u_CH
Orient: R90
Pad: PcornerUR NE PADSPACE_C_74x74u_CH
Orient: R180
Pad: PcornerUL NW PADSPACE_C_74x74u_CH

# # ------------------------------------------------ #
# # NORTH
# # ------------------------------------------------ #
Pad: PGND1    N CPAD_S_74x50u_GND
Pad: InPads[4].InPad N CPAD_S_74x50u_IN
Pad: InPads[5].InPad N CPAD_S_74x50u_IN
Pad: InPads[6].InPad N CPAD_S_74x50u_IN
Pad: InPads[7].InPad N CPAD_S_74x50u_IN
Pad: InPads[8].InPad N CPAD_S_74x50u_IN
Pad: InPads[9].InPad N CPAD_S_74x50u_IN
Pad: PGND2    N CPAD_S_74x50u_GND
# # ------------------------------------------------ #
# # WEST 
# # ------------------------------------------------ #
Pad: clkpad   W CPAD_S_74x50u_IN
Pad: InPad W CPAD_S_74x50u_IN
Pad: InPads[2].InPad W CPAD_S_74x50u_IN
Pad: InPads[3].InPad W CPAD_S_74x50u_IN
Pad: spi_clk_pad   W CPAD_S_74x50u_IN
Pad: jtag_clk_pad  W CPAD_S_74x50u_IN
# # ------------------------------------------------ #
# # SOUTH
# # ------------------------------------------------ #
Pad: PVDD1    S CPAD_S_74x50u_VDD
Pad: InPads[10].InPad S CPAD_S_74x50u_IN
Pad: InPads[11].InPad S CPAD_S_74x50u_IN
Pad: InPads[12].InPad S CPAD_S_74x50u_IN
Pad: InPads[13].InPad S CPAD_S_74x50u_IN
Pad: OutPads[6].OutPad S CPAD_S_74x50u_OUT
Pad: OutPads[7].OutPad S CPAD_S_74x50u_OUT
Pad: OutPads[8].OutPad S CPAD_S_74x50u_OUT
Pad: PVDD2    S CPAD_S_74x50u_VDD
# # ------------------------------------------------ #
# # EAST 
# # ------------------------------------------------ #
Pad: OutPads[0].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[1].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[2].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[3].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[4].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[5].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[9].OutPad E CPAD_S_74x50u_OUT
Pad: OutPads[10].OutPad E CPAD_S_74x50u_OUT



