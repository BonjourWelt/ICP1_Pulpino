// ======================================================
// Simplified Single-Port RAM Wrapper – 1024x8 SRAM
// ======================================================
`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

module ram_wrapper(
  input  logic                  clk,
  input  logic                  write_en,     // Write enable
  input  logic                  read_en,      // Read enable
  input  logic [ADDR_WIDTH-1:0] addr,
  input  logic [DATA_WIDTH-1:0] ram_data_in,
  output logic [DATA_WIDTH-1:0] ram_data_out,
  output logic                  ry
);

  //TODO: the reset signal above doesnt do anything
  //TODO: change ram address bits in define_pkg if using different ram

  /*
  ST_SPHDL_2048x8m8_L
  ST_SPHDL_1024x8m8_L 

  ST_SPHS_2048x8m8_L 
  ST_SPHS_1024x8m8_L*/
  
  ST_SPHDL_1024x8m8_L u_sram (
    .CK      ( clk ),
    .CSN     (~(write_en | read_en)), 
    .A       ( addr ),
    .WEN     (~write_en),                 
    .D       ( ram_data_in ),
    .Q       ( ram_data_out ),
    .RY      ( ry ),
    .TBYPASS ( 1'b0 )                
  );

endmodule

