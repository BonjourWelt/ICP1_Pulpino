// ======================================================
// Top-Level Integration: Controller (with 4 RAMs) + CA
// ======================================================

`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

module top_file_convolution 
(
    input  logic                   clk,
    input  logic                   rst_n,

    // Software/Stimulus Side
    input  logic                   start_APB,
    input  logic [1:0]             channel_top,

    input  logic                   write_en_APB,
    input  logic                   valid_input_APB,
    input  logic [ADDR_WIDTH-1:0]  write_addr_APB,
    input  logic [DATA_WIDTH-1:0]  write_data_APB,

    output logic [DATA_WIDTH-1:0]  read_APB_data_top,
    input  logic                   read_cmd_APB_top,
    input  logic [ADDR_WIDTH-1:0]  read_apb_addr_top,
    output logic                   CA_finished,
    input logic                    CA_reset_top,

    // Output to observe RAM ready
    output logic                   ry_APB
);

    // ===== Internal Signals =====
    logic                         burst_read_top;
    logic                         write_req_top;
    logic [DATA_WIDTH-1:0]        CA_output_top;
    logic [ADDR_WIDTH-1:0]        write_addr_top;
    logic                         burst_ready_top;

    logic [DATA_WIDTH-1:0]        ram1_output_top;
    logic [DATA_WIDTH-1:0]        ram2_output_top;
    logic [DATA_WIDTH-1:0]        ram3_output_top;
    logic [DATA_WIDTH-1:0]        ram4_output_top;

    logic                         ry_valid_i;

    logic                         wr_handshake_top;
    logic                         rd_knl_rq_top;
    logic [ADDR_WIDTH-1:0]        rd_addr_CA_top;
    logic                         use_kernel_addr_top;

    logic                         read_cmd_APB_i;
    logic [ADDR_WIDTH-1:0]        read_apb_addr_i;
    logic                         CA_finished_i;
    logic                         CA_reset_top_i;
    logic [1:0] channel_mux;

    // ===============================================
    // Output Logic
    // ===============================================
    always_comb begin
        // Select channel for write phase only
        channel_mux = (write_en_APB == 1'b1) ? channel_top : 2'd0;

        // Direct pass-through of RAM4 read interface signals
        read_APB_data_top   = ram4_output_top;
        CA_finished         = CA_finished_i;
    end

    // ===============================================
    // Input Logic
    // ===============================================
    always_comb begin
        read_cmd_APB_i  = read_cmd_APB_top;
        read_apb_addr_i = read_apb_addr_top;
        CA_reset_top_i  = CA_reset_top;

    end

    // --------------------------------------------------
    // Controller Instance
    // --------------------------------------------------
    ram_controller_conv u_ctrl 
    (
        .clk                (clk),
        .rst_n              (rst_n),
        // interface with APB and RAM controller
        .channel_ctrl       (channel_mux),

        // interface with APB
        .write_en_APB       (write_en_APB),
        .valid_input_APB    (valid_input_APB),
        .write_data_APB     (write_data_APB),
        .write_addr_APB     (write_addr_APB),

        .read_cmd_APB       (read_cmd_APB_i),
        .read_apb_addr      (read_apb_addr_i),

        // interface with CA
        .start              (start_APB),
        .burst_rd_rq_i      (burst_read_top),
        .burst_rd_handshake (burst_ready_top),
        .rd_knl_rq_i        (rd_knl_rq_top),
        .rd_addr_CA         (rd_addr_CA_top),
        .use_kernel_addr    (use_kernel_addr_top),
        .ram1_output        (ram1_output_top),
        .ram2_output        (ram2_output_top),
        .ram3_output        (ram3_output_top),
        .wr_rq_CA_i         (write_req_top),
        .wr_data_CA         (CA_output_top),
        .wr_addr_CA         (write_addr_top),
        .wr_handshake       (wr_handshake_top),
        .ry                 (ry_APB),

        // interace with both CA and APB
        .ram4_output        (ram4_output_top),
        .CA_finished_i      (CA_finished_i)

    );

    // --------------------------------------------------
    // Real CA Controller Instance
    // --------------------------------------------------
    CA_controller u_ca 
    (
        .clk               (clk),
        .rst_n             (rst_n),
        .start             (start_APB),
        .CA_finished       (CA_finished_i),
        .CA_reset_CA       (CA_reset_top_i),
        .wr_rq             (write_req_top),
        .wr_handshake_i    (wr_handshake_top),
        .wr_addr           (write_addr_top),
        .CA_output         (CA_output_top),
        .rd_rq             (burst_read_top),
        .rd_handshake_i    (burst_ready_top),
        .rd_knl_rq         (rd_knl_rq_top),
        .rd_addr_CA        (rd_addr_CA_top),   
        .use_kernel_addr   (use_kernel_addr_top),  
        .ram1_output       (ram1_output_top),
        .ram2_output       (ram2_output_top),
        .ram3_output       (ram3_output_top)
    );

endmodule
