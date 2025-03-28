// Copyright 2017 ETH Zurich and University of Bologna.
//Last edit: 2025.3.27. Change to right ram.

`include "config.sv"

module sp_ram_wrap
  #(
    parameter RAM_SIZE   = 32768,              // in bytes
    parameter ADDR_WIDTH = $clog2(RAM_SIZE),
    parameter DATA_WIDTH = 32,
    parameter TOTAL_COUNTER_WIDTH = 15;
  )(
    // Clock and Reset
    input  logic                    clk,
    input  logic                    rstn_i, //idk what to do with this
    input  logic                    en_i,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i,
    input  logic                    bypass_en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata_o,
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

//-----------------------------------------------------------------
    //  WRITE operations
   logic [ADDR_WIDTH-1:0] current_addr; 
   assign current_addr = addr_i;
   integer counter [TOTAL_COUNTER_WIDTH];
   integer k;

   always @(posedge clk) begin
    if (en_i && we_i) begin
        // Loop to handle multiple data writes based on byte enable
        for (k = 0; k < DATA_WIDTH/8; k++) begin
            if (be_i[k]) begin
                // Non-blocking assignment for addr update
                addr[counter[10:0]] <= wdata[k];  
            end
        end  
        // Non-blocking update of counter
        counter <= counter + 1;  
    end
end
//-------------------------------------------
    // Enabling and instantiation and READoperation
   logic bank_select =counter [14:11]; // 4-bit bank selection
   logic [7:0] sram_rdata [15:0];      // Data READ from each SRAM bank
 
   // Generate 16 SRAM instances
   genvar i;
   generate
     for (i = 0; i < 16; i++) begin : sram_banks
        ST_SPHDL_2048x8m8_L u_sram (
         .CK (clk),
         .WEN(we_i && (bank_select == i)), // Enable only the selected SRAM
         .CSN (en_i),
         .TBYPASS(bypass_en_i),
         .Q (rdata_o ),
         .RY (),  //havent decided how to connect this yet
         .D (wdata_i ),
         .A (addr_i )
       );
     end
   endgenerate
   // Output data from the selected SRAM bank
   assign rdata = sram_rdata[bank_select];
`endif

endmodule
