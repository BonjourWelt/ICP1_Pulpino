
// ===================================================================================
//  Signal declerations
// ===================================================================================
/*
Problem:
we stay in MU state a fix number of cycles. if handshake arrives at a non-fixed time the
amount of shift will be messed up. W need 1 single cycle after write handshake.
SOLUTION: handshake with DONE signal from MU since when that is asserted we can stop shifting regardless of weather or not values are written into ram.
Done causes an extra shift
SOLUTION 2: use wr_handshake. Nope handshake remains on for too long.
SOLUTION 3: use a handshake with shifter itself
*/


`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

module CA_controller 
(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     start,

    output logic                     CA_finished,
    input logic                     CA_reset_CA,

    output logic                     wr_rq,
    input  logic                     wr_handshake_i,
    output logic [ADDR_WIDTH-1:0]    wr_addr,
    output logic [DATA_WIDTH-1:0]    CA_output,

    output logic                     rd_rq,
    input  logic                     rd_handshake_i,

    output logic                     rd_knl_rq,
    output logic [ADDR_WIDTH-1:0]    rd_addr_CA,
    output logic                     use_kernel_addr,

    input logic [DATA_WIDTH-1:0]     ram1_output,
    input logic [DATA_WIDTH-1:0]     ram2_output,
    input logic [DATA_WIDTH-1:0]     ram3_output
);
// ===================================================================================
//  Signal declerations
// ===================================================================================
    typedef enum logic [2:0] {
        CA_IDLE        = 3'd0,
        CA_LOAD_KERNEL = 3'd1,
        CA_MU          = 3'd2,
        CA_SUM         = 3'd3,
        CA_WRITE       = 3'd4,
        CA_DONE        = 3'd5
    } ca_state_t;

    ca_state_t curr_state, next_state;

    // ===================
    // Registers and Output Signal Wires
    // ===================
    logic [3:0]          kernel_counter,       next_kernel_counter;
    logic [7:0]          MU_CA_counter,           next_MU_CA_counter;
    logic [4:0]          wr_counter,           next_wr_counter;
    logic [9:0]          iteration_count,      next_iteration_count;
    logic [ADDR_WIDTH:0] write_base_addr,      next_write_base_addr;

    logic [DATA_WIDTH-1:0]  CA_output_i;
    logic [ADDR_WIDTH-1:0]    wr_addr_i;

    logic comb_rd_rq;
    logic comb_wr_rq;
    logic retrieved_handshake;

    logic next_finished;

    logic [ADDR_WIDTH-1:0] kernel_base_addr;

    logic [DATA_WIDTH-1:0] shifter_out_ch1, shifter_out_ch2, shifter_out_ch3;
    logic [DATA_WIDTH-1:0] shifter_in_ch1, shifter_in_ch2, shifter_in_ch3;
    logic                  shifter_write_ch1, shifter_write_ch2, shifter_write_ch3;
    logic                  shift_en_ch1, shift_en_ch2, shift_en_ch3;

    logic [9:0] ofm_sum,         next_ofm_sum; 
    logic [7:0] ofm_pixel_sat,   next_ofm_pixel_sat;
    logic [9:0] temp_sum;

    // ===================
    // MU Control 
    // ===================
    logic        MU_start;
    logic        MU1_done,        MU2_done,        MU3_done;
    logic [7:0]  MU1_ofm,         MU2_ofm,         MU3_ofm;
    logic [7:0]  MU1_patch_in,    MU2_patch_in,    MU3_patch_in;
    logic [7:0]  MU1_kernel_in,   MU2_kernel_in,   MU3_kernel_in;

    // ===================
    // Clock Gates
    // ===================
    logic testmode_i = 1'b0;

    logic clk_writer;


// ===================================================================================
//  Output logic
// ===================================================================================

    assign rd_rq                       = comb_rd_rq;
    assign wr_rq                       = comb_wr_rq;
    assign CA_finished                 = next_finished;
    assign CA_output                   = CA_output_i;
    assign wr_addr                     = wr_addr_i;

// ===================================================================================
//  Control Path
// ===================================================================================

    always_comb begin

        next_state = curr_state;

        case (curr_state)
            //============================================
            CA_IDLE:
                if (start) begin
                    next_state = CA_LOAD_KERNEL;
                end
            //============================================
            CA_LOAD_KERNEL:
                if (kernel_counter == BURST_SIZE+2) begin
                    next_state = CA_MU;
                    /*10 cycles as we arent shifting anything on first
                    need to wait for rd_hanshake from ram_ctrl*/
                end
            //============================================
            CA_MU:
                if (MU_CA_counter == BURST_SIZE+1) begin
                    next_state = CA_SUM;
                end
            //============================================      
            CA_SUM:
                if (MU1_done && MU2_done && MU3_done) begin
                    next_state = CA_WRITE;
                end
            //============================================
            CA_WRITE:
                if (wr_handshake_i) begin
                    //TODO:
                    /*
                    since we dont want the computation to continue at iter=28 and hapen one last time we should update it before reach this state. We can simply update it in the sum state. Since we write 1 pixel of ofm then iter_cnt must be equal to number of pixels in ofm so 784 (0-783)
                    */
                    if (iteration_count == ITERATION_COUNT) begin
                            next_state = CA_DONE;
                    end else begin
                            next_state = CA_MU;
                    end
                end

            //============================================
            CA_DONE:
                if (CA_reset_CA) begin
                    next_state = CA_IDLE;
                end else begin
                    next_state = CA_DONE;
                end

        endcase
    end
// ===================================================================================
//  Datapath
// ===================================================================================

    always_comb begin

        // ====Defaults========
        // --------------------------
        // Control Flags
        // --------------------------
        next_finished           = 1'b0;
        MU_start                = 1'b0;

        // --------------------------
        // Request and Output Interface
        // --------------------------
        comb_rd_rq              = 1'b0;
        CA_output_i             = '0;

        comb_wr_rq              = 1'b0;
        wr_addr_i               = '0;
        next_write_base_addr    = write_base_addr;
        next_ofm_sum            = ofm_sum;  

        rd_knl_rq               = 1'b0;
        rd_addr_CA              = '0;
        use_kernel_addr         = 1'b0;

        // --------------------------
        // Counters 
        // --------------------------
        next_MU_CA_counter      = MU_CA_counter;
        next_kernel_counter     = kernel_counter;
        next_wr_counter         = wr_counter;
        next_iteration_count    = iteration_count;

        // Shifter control default
        shifter_write_ch1 = 1'b0;    shifter_write_ch2 = 1'b0;    shifter_write_ch3 = 1'b0;
        shift_en_ch1      = 1'b0;    shift_en_ch2      = 1'b0;    shift_en_ch3      = 1'b0;
        shifter_in_ch1    = '0;      shifter_in_ch2    = '0;      shifter_in_ch3    = '0;

        //------------------------
        // Power saving:
            // Input isolation for MUs (reduce external toggling)
            MU1_patch_in  = (curr_state == CA_MU) ? ram1_output     : '0;
            MU2_patch_in  = (curr_state == CA_MU) ? ram2_output     : '0;
            MU3_patch_in  = (curr_state == CA_MU) ? ram3_output     : '0;

            MU1_kernel_in = (curr_state == CA_MU) ? shifter_out_ch1 : '0;
            MU2_kernel_in = (curr_state == CA_MU) ? shifter_out_ch2 : '0;
            MU3_kernel_in = (curr_state == CA_MU) ? shifter_out_ch3 : '0;

        //

        case (curr_state)
            //============================================
            CA_LOAD_KERNEL: begin
                //load 3 kernels
                rd_knl_rq  =1'b1; 
                
                        if (kernel_counter < BURST_SIZE+2) begin
                            next_kernel_counter = kernel_counter +1; 
                        end else begin
                            next_kernel_counter = 0;  
                        end
                //-------------------------------------------
                if (rd_handshake_i) begin
                    shifter_write_ch1 = 1;
                    shifter_write_ch2 = 1;
                    shifter_write_ch3 = 1;
                    shifter_in_ch1 = ram1_output;
                    shifter_in_ch2 = ram2_output;
                    shifter_in_ch3 = ram3_output;
                end
            end

            //============================================
            CA_MU: begin

                comb_rd_rq =1'b1; 
     
                //-------------------------------------------
                if (rd_handshake_i) begin

                    //counter after handshake
                    next_MU_CA_counter = MU_CA_counter +1; 
                    // move its reset to sum state

                    MU_start = 1;

                    // prevent further shifts. Need one extra shift to reset shifter
                    if (MU_CA_counter < BURST_SIZE+1) begin
                        shift_en_ch1 = 1;
                        shift_en_ch2 = 1;
                        shift_en_ch3 = 1;
                    end

                    MU1_kernel_in = shifter_out_ch1;
                    MU2_kernel_in = shifter_out_ch2;
                    MU3_kernel_in = shifter_out_ch3;

                    MU1_patch_in  = ram1_output;
                    MU2_patch_in  = ram2_output;
                    MU3_patch_in  = ram3_output;                    
                end
            end 

            //============================================      
            CA_SUM: begin

                // reset counter from previous state
                next_MU_CA_counter = 0; 
                //TODO: 
                /*the outputs of the MUs are registered so no need to register here
                as well. THey can be combinationally given.
                actually we need this in the write state so must be registered
                we calculated it here but write in next
                is it better to simply also write it in the next?
                problem:
                These depend on done and done is asserted after write handshake in the next
                    state   
                    */

                next_iteration_count = iteration_count +1;
                    
                if (MU1_done && MU2_done && MU3_done) begin

                    temp_sum = MU1_ofm + MU2_ofm + MU3_ofm;

                    // saturation logic 
                    if (temp_sum > 10'd255)
                        next_ofm_pixel_sat = 8'd255;
                    else
                        next_ofm_pixel_sat = temp_sum[7:0];
                end


            end
            //============================================
            CA_WRITE: begin
                comb_wr_rq     = 1'b1;

                //TODO: 
                /* how many cycles? 1 as soon as handshake is asserted
                we send data and address combinationally which doesnt 
                need clock edge*/

                //------------------------------------
                if (wr_handshake_i) begin

                    CA_output_i         = ofm_pixel_sat;

                    wr_addr_i           = write_base_addr ;
                    next_write_base_addr= write_base_addr +1;

                end 
            end           
            //============================================
            CA_DONE: begin
                next_finished = 1'b1;
                next_write_base_addr = '0;
                next_iteration_count = '0;
                next_MU_CA_counter      = '0;
                next_kernel_counter     = '0;
                next_wr_counter         = '0;
                next_ofm_sum         = 10'd0;
                next_ofm_pixel_sat   = 8'd0;
                CA_output_i          = 8'd0;
                wr_addr_i            = '0;

            end
            //============================================

        endcase
    end

// ===================================================================================
//  Register Updates
// ===================================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // FSM state
            curr_state         <= CA_IDLE;
            // Counters and iteration
            MU_CA_counter         <= 0;
            kernel_counter     <= 0;
            wr_counter         <= 0;
            iteration_count    <= 0;
            // Address/channel tracking
            write_base_addr    <= 0;
            // Output sum
            ofm_sum            <= 10'd0;
            ofm_pixel_sat      <= '0;

        //-------------------------------------------------------------
        end else begin
            // FSM state
            curr_state         <= next_state;
            // Counters and iteration
            MU_CA_counter         <= next_MU_CA_counter;
            kernel_counter     <= next_kernel_counter;
            wr_counter         <= next_wr_counter;
            iteration_count    <= next_iteration_count;
            // Address/channel tracking
            write_base_addr    <= next_write_base_addr;
            // Output sum
            ofm_sum            <= next_ofm_sum;
            ofm_pixel_sat      <= next_ofm_pixel_sat;
        end
    end

// ===================================================================================
//  Instantiations
// ===================================================================================

 // Instantiate 3 MUs
    MU_conv MU1 (
        .clk(clk),
        .rst(rst_n),
        .MU_start(MU_start),
        .patch_in(MU1_patch_in),
        .kernel_in(MU1_kernel_in),
        .wr_handshake_i (wr_handshake_i),  
        .done(MU1_done),
        .MU_ofm(MU1_ofm)
    );

    MU_conv MU2 (
        .clk(clk),
        .rst(rst_n),
        .MU_start(MU_start),
        .patch_in(MU2_patch_in),
        .kernel_in(MU2_kernel_in),
        .wr_handshake_i (wr_handshake_i),  
        .done(MU2_done),
        .MU_ofm(MU2_ofm)
    );

    MU_conv MU3 (
        .clk(clk),
        .rst(rst_n),
        .MU_start(MU_start),
        .patch_in(MU3_patch_in),
        .kernel_in(MU3_kernel_in),
        .wr_handshake_i (wr_handshake_i),  
        .done(MU3_done),
        .MU_ofm(MU3_ofm)
    );

    shifter_conv sh1 (
        .clk           (clk),
        .rst_n         (rst_n),
        .shift_en      (shift_en_ch1),
        .shifter_write (shifter_write_ch1),
        .shifter_in    (shifter_in_ch1),
        .shifter_out   (shifter_out_ch1)
    );

    shifter_conv sh2 (
        .clk           (clk),
        .rst_n         (rst_n),
        .shift_en      (shift_en_ch2),
        .shifter_write (shifter_write_ch2),
        .shifter_in    (shifter_in_ch2),
        .shifter_out   (shifter_out_ch2)
    );

    shifter_conv sh3 (
        .clk           (clk),
        .rst_n         (rst_n),
        .shift_en      (shift_en_ch3),
        .shifter_write (shifter_write_ch3),
        .shifter_in    (shifter_in_ch3),
        .shifter_out   (shifter_out_ch3)
    );


endmodule
