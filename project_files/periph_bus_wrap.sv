// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "apb_bus.sv"

 //Updated wrapper to exclude peripherals that were removed from "pulpino_top.sv" and "peripherals.sv"

module periph_bus_wrap
  #(
    parameter APB_ADDR_WIDTH = 32,
    parameter APB_DATA_WIDTH = 32
    )
   (
    input logic       clk,
    input logic       rst_n,

    APB_BUS.Slave     apb_slave,

    APB_BUS.Master    uart_master,
    APB_BUS.Master    gpio_master,  //Readded gpio
    APB_BUS.Master    timer_master,
    APB_BUS.Master    event_unit_master,
    APB_BUS.Master    soc_ctrl_master,
    APB_BUS.Master    debug_master

    );

  localparam NB_MASTER      = `NB_MASTER;

  logic [NB_MASTER-1:0][APB_ADDR_WIDTH-1:0] s_start_addr;
  logic [NB_MASTER-1:0][APB_ADDR_WIDTH-1:0] s_end_addr;

  APB_BUS
    #(
      .APB_ADDR_WIDTH(APB_ADDR_WIDTH),
      .APB_DATA_WIDTH(APB_DATA_WIDTH)
      )
  s_masters[NB_MASTER-1:0]();

  APB_BUS
    #(
      .APB_ADDR_WIDTH(APB_ADDR_WIDTH),
      .APB_DATA_WIDTH(APB_DATA_WIDTH)
      )
  s_slave();

  `APB_ASSIGN_SLAVE(s_slave, apb_slave);

  `APB_ASSIGN_MASTER(s_masters[0], uart_master);
  assign s_start_addr[0] = `UART_START_ADDR;
  assign s_end_addr[0]   = `UART_END_ADDR;

  `APB_ASSIGN_MASTER(s_masters[1], gpio_master); //Readded gpio
  assign s_start_addr[1] = `GPIO_START_ADDR;
  assign s_end_addr[1]   = `GPIO_END_ADDR;

  `APB_ASSIGN_MASTER(s_masters[2], timer_master);
  assign s_start_addr[2] = `TIMER_START_ADDR;
  assign s_end_addr[2]   = `TIMER_END_ADDR;

  `APB_ASSIGN_MASTER(s_masters[3], event_unit_master);
  assign s_start_addr[3] = `EVENT_UNIT_START_ADDR;
  assign s_end_addr[3]   = `EVENT_UNIT_END_ADDR;

  `APB_ASSIGN_MASTER(s_masters[4], soc_ctrl_master);
  assign s_start_addr[4] = `SOC_CTRL_START_ADDR;
  assign s_end_addr[4]   = `SOC_CTRL_END_ADDR;

  `APB_ASSIGN_MASTER(s_masters[5], debug_master);
  assign s_start_addr[5] = `DEBUG_START_ADDR;
  assign s_end_addr[5]   = `DEBUG_END_ADDR;

  //********************************************************
  //**************** SOC BUS *******************************
  //********************************************************

  apb_node_wrap
  #(
    .NB_MASTER      ( NB_MASTER      ),
    .APB_ADDR_WIDTH ( APB_ADDR_WIDTH ),
    .APB_DATA_WIDTH ( APB_DATA_WIDTH )
  )
  apb_node_wrap_i
  (
    .clk_i        ( clk        ), 
    .rst_ni       ( rst_n       ), 

    .apb_slave    ( s_slave      ),
    .apb_masters  ( s_masters    ),

    .start_addr_i ( s_start_addr ),
    .end_addr_i   ( s_end_addr   )
  );

endmodule
