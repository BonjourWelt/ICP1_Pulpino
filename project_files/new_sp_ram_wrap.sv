//Edited sp_ram_wrap for replacing 8192*32 RAM with 16 2048*8 RAMs 
//Last edit: 2025.3.23 Created the first version.
//Last edit: 2025.3.26 Changed the structural logic to 4 groups with 4 rams in each group. Now we don't write each 32 bits data in one 2048 ram, 
              //rather break it down into 4 sections, and write each section in one of the 4 rams in the same group.
              //Adress break down: [14:4] <= 11 bits address in each 2048*8 ram;
              //                   [3:2] <= 2 bits for selecting one of 4 ram groups;
              //                   [1:0] <= unused bits.
//Last edit: 2025.3.28 Modified the group_sel signal and signals connection. 

`include "config.sv"

module sp_ram_wrap
  #(
    parameter RAM_SIZE   = 32768,              // in bytes
    parameter ADDR_WIDTH = $clog2(RAM_SIZE),
    parameter DATA_WIDTH = 32
  )(
    // Clock and Reset
    input  logic                    clk,
    input  logic                    rstn_i,
    input  logic                    en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata_o,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i,
    input  logic                    bypass_en_i
  );

`ifdef PULP_FPGA_EMUL
  xilinx_mem_8192x32
  sp_ram_i
  (
    .clka   ( clk                    ),
    .rsta   ( 1'b0                   ), // reset is active high

    .ena    ( en_i                   ),
    .addra  ( addr_i[ADDR_WIDTH-1:2] ),
    .dina   ( wdata_i                ),
    .douta  ( rdata_o                ),
    .wea    ( be_i & {4{we_i}}       )
  );

  // TODO: we should kill synthesis when the ram size is larger than what we
  // have here

`elsif ASIC
   // RAM bypass logic
   logic [31:0] ram_out_int;
   // assign rdata_o = (bypass_en_i) ? wdata_i : ram_out_int;
   assign rdata_o = ram_out_int;

   sp_ram_bank
   #(
    .NUM_BANKS  ( RAM_SIZE/4096 ),
    .BANK_SIZE  ( 1024          )
   )
   sp_ram_bank_i
   (
    .clk_i   ( clk                     ),
    .rstn_i  ( rstn_i                  ),
    .en_i    ( en_i                    ),
    .addr_i  ( addr_i                  ),
    .wdata_i ( wdata_i                 ),
    .rdata_o ( ram_out_int             ),
    .we_i    ( (we_i & ~bypass_en_i)   ),
    .be_i    ( be_i                    )
   );

`else
 // RAM parameter
  localparam RAM_COUNT = 16;   // 16 RAMs，2048x8bit each

  logic [10:0] addr_ram;       // 11-bit RAM internal address
  logic [1:0] group_sel;       // RAM group selection 

  assign addr_ram = addr_i[12:2];
	always @(posedge clk or rstn_i) begin
   if (~rstn_i)
   group_sel <= 0;
	 else 
		group_sel <= addr_i[14:13];   
	end
  // 16 outputs of RAMs
  logic [7:0] ram_dout[RAM_COUNT-1:0];

  // 16 RAMs instantiation
  genvar i;
  generate
    for (i = 0; i < RAM_COUNT; i = i + 1) begin : ram_block
      ST_SPHDL_2048x8m8_L u_sram (
        .CK    ( clk      ),
        .CSN( ~(en_i & (addr_i[14:13] == (i/4)) & ((we_i & be_i[i%4]) | ~we_i) ) ), // RAM selection
        .A ( addr_ram ),
        .WEN   ( ~we_i  ), 
        .D( wdata_i[(i%4)*8 +: 8] ), // input 
        .Q( ram_dout[i] ),
        .RY(),
        .TBYPASS( bypass_en_i )
      );
    end
  endgenerate

  // Output( combine 4 RAMs to 32-bit data)
  always_comb begin
    case (group_sel)
	
      2'b00: rdata_o = {ram_dout[3], ram_dout[2], ram_dout[1], ram_dout[0]};
      2'b01: rdata_o = {ram_dout[7], ram_dout[6], ram_dout[5], ram_dout[4]};
      2'b10: rdata_o = {ram_dout[11], ram_dout[10], ram_dout[9], ram_dout[8]};
      2'b11: rdata_o = {ram_dout[15], ram_dout[14], ram_dout[13], ram_dout[12]};
    endcase
  end
`endif

endmodule

//ram_block[0]/u_sram/D
//# ** Error: (vish-4014) No objects found matching '/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/ram_block[0]/u_sram/D'.
//add wave -noupdate -radix hexadecimal {/tb/top_i/core_region_i/instr_mem/sp_ram_wrap_i/sp_ram_i}
