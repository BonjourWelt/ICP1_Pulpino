// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


module clk_rst_gen
(
    input  logic                            clk_i,
    input  logic                            rstn_i,

    output logic                            clk_o,
    output logic                            rstn_o
);

  //----------------------------------------------------------------------------//
  // Reset synchronizer
  //----------------------------------------------------------------------------//
  rstgen i_rst_gen_soc
  (
      // PAD FRAME SIGNALS
      .clk_i               ( clk_i         ),
      .rst_ni              ( rstn_i          ),

      // TEST MODE
      .test_mode_i         ( testmode_i      ),

      // OUTPUT RESET
      .rst_no              ( rstn_o          ),
      .init_no             (                 )
  );


  assign clk_o = clk_i;

endmodule
