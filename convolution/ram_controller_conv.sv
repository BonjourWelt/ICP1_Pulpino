
`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

// ===================================================================================
//  RAM Controller with Zero padding generator
// ===================================================================================
module ram_controller_conv
(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   start,
    input  logic [1:0]             channel_ctrl,
    input  logic                   CA_finished_i,

    input  logic                   write_en_APB,
    input  logic                   valid_input_APB,
    input  logic [DATA_WIDTH-1:0]  write_data_APB,
    input  logic [ADDR_WIDTH-1:0]  write_addr_APB,
    input  logic                   read_cmd_APB,
    input  logic [ADDR_WIDTH-1:0]  read_apb_addr,
    
    // ===== Interface to CA =====
    input  logic                   burst_rd_rq_i,
    output logic                   burst_rd_handshake,

    input  logic                   rd_knl_rq_i,
    
    output logic [DATA_WIDTH-1:0]  ram1_output,
    output logic [DATA_WIDTH-1:0]  ram2_output,
    output logic [DATA_WIDTH-1:0]  ram3_output,
    output logic [DATA_WIDTH-1:0]  ram4_output,

    input  logic                   wr_rq_CA_i,
    output logic                   wr_handshake,
    input  logic [DATA_WIDTH-1:0]  wr_data_CA,
    input  logic [ADDR_WIDTH-1:0]  wr_addr_CA,


    input  logic [ADDR_WIDTH-1:0]  rd_addr_CA,  
    input  logic                   use_kernel_addr, 
    // ===== RAM Status =====
    output logic                   ry
);

// ===================================================================================
//  Signal declerations
// ===================================================================================

    typedef enum logic [2:0] {
        IDLE         = 3'd0,
        FILLING_RAM  = 3'd1,
        KERNEL_READ  = 3'd2,
        RAM_READ   = 3'd3,
        RAM_WRITE = 3'd4
    } state_t;

    state_t curr_state, next_state;

    logic [7:0]               burst_cnt, next_burst_cnt;
    logic [ADDR_WIDTH-1:0]    burst_addr, next_burst_addr;
    logic [7:0] result_counter, next_result_counter;

    logic [ADDR_WIDTH-1:0]    addr_to_ram1,addr_to_ram2,addr_to_ram3, addr_to_ram4;
    logic [DATA_WIDTH-1:0]    ram1_input,ram2_input,ram3_input, ram4_input;
    logic [DATA_WIDTH-1:0]    ram1_output_i, ram2_output_i, ram3_output_i, ram4_output_i;

    logic  we_ram1, we_ram2, we_ram3, we_ram4;
    logic  re_ram1, re_ram2, re_ram3, re_ram4;

    logic [1:0] selected_channel, next_selected_channel;
    logic kernel_active, next_kernel_active;

    logic  ry_i;
    assign ry                 = ry_i;
    logic delayed_re_ram4, next_delayed_re_ram4;
    logic ry_valid, next_ry_valid;
    assign ry_valid_ctrl = ry_valid;
    
    // Handshakes
    logic delayed_rd_handshake, next_delayed_rd_handshake;
    assign burst_rd_handshake = delayed_rd_handshake;
 

    // Patch Generator Signals
    logic [ADDR_WIDTH-1:0] patch_addr;
    logic zero_pad;
    logic valid_patch;
    logic done_1_patch;
    logic enable_patch;

    logic [3:0] patch_gen_cnt, next_patch_gen_cnt;

    logic [ADDR_WIDTH-1:0] read_addr;
    assign read_addr = (use_kernel_addr == 1'b1) ? rd_addr_CA : patch_addr;

// ===================================================================================
//  Output Logic: Masking Logic for Padding 
// ===================================================================================

    always_comb begin
        if (zero_pad == 1'b1) begin
            // Send zero if pad is enabled
            ram1_output = '0;                     
            ram2_output = '0;
            ram3_output = '0;
            ram4_output = '0;
        end else begin 
        // Otherwise, forward actual RAM data
            ram1_output        = ram1_output_i;
            ram2_output        = ram2_output_i;
            ram3_output        = ram3_output_i;
            ram4_output        = ram4_output_i;
        end
    end
// ===================================================================================
//  Combinational Control Path
// ===================================================================================

    always_comb begin
    next_state = curr_state;

        case (curr_state)
            //-------------------------------------
            IDLE: begin
                if (write_en_APB)
                    next_state = FILLING_RAM;
                else if (rd_knl_rq_i)
                    next_state = KERNEL_READ;
                else if (burst_rd_rq_i)
                    next_state = RAM_READ;
                else if (wr_rq_CA_i)
                    next_state = RAM_WRITE;
            end
            //-------------------------------------
            FILLING_RAM: begin
                if (start)
                    next_state = IDLE;
            end
            //-------------------------------------
            KERNEL_READ:
                if (burst_cnt == BURST_SIZE +1) begin
                    //burst hand only increments after handshake
                    next_state = IDLE;
                end
            //-------------------------------------
            RAM_READ: begin
                if (burst_cnt == RA_RD_CYCLES) begin
                    next_state = IDLE;
                end
            end
            //-------------------------------------
            RAM_WRITE: begin
                next_state = IDLE;
                /*if (result_counter == result_state_cycles) begin 
                    next_state = IDLE;
               end*/
            end
        endcase
    end
// ===================================================================================
//  Combinational Datapath and Output Logic
// ===================================================================================

    always_comb begin
        addr_to_ram1 = '0; ram1_input = '0; we_ram1 = 1'b0; re_ram1 = 1'b0;
        addr_to_ram2 = '0; ram2_input = '0; we_ram2 = 1'b0; re_ram2 = 1'b0;
        addr_to_ram3 = '0; ram3_input = '0; we_ram3 = 1'b0; re_ram3 = 1'b0;
        addr_to_ram4 = '0; ram4_input = '0; we_ram4 = 1'b0; re_ram4 = 1'b0;

        next_burst_cnt            = burst_cnt;
        next_burst_addr           = burst_addr;
        next_result_counter       = result_counter; //TODO: it was 0
        next_delayed_rd_handshake = delayed_rd_handshake;
        next_selected_channel     = selected_channel;
        next_kernel_active        = kernel_active;
        next_burst_addr           = burst_addr;
        enable_patch              = 1'b0;
        wr_handshake              = 1'b0;
        next_ry_valid             = 1'b0;

        // ===============================================
        // RAM4 External Access ONLY when CA is finished
        // ===============================================

        if (read_cmd_APB == 1'b1 && CA_finished_i == 1'b1) begin
            addr_to_ram4    = read_apb_addr;       // Externally supplied address
            re_ram4         = 1'b1;                // Assert read enable to RAM4
            next_ry_valid   = 1'b1;
        end

        //=============================================================================
        case (curr_state)
            //-----------------------------------------
            IDLE: begin
                if (write_en_APB) begin
                //TODO: channel and write_en have to be asserted together
                next_selected_channel = channel_ctrl;
                end
            end

            //-----------------------------------------
            FILLING_RAM: begin
                /*this needs all 3 at the same time:
                        APB latched data
                        APB latched addr
                        APB latched valid_input*/
                    if (write_en_APB) begin
                    //TODO: channel and write_en have to be asserted together
                    /* we have this here to so we dont go back to idle state
                      channel is changed 1 cycle later so when changing channel valid must not be asserted
                        */ 
                    next_selected_channel = channel_ctrl;
                    end

                    if (valid_input_APB) begin

                            if (selected_channel == 2'd0) begin
                                addr_to_ram1 = write_addr_APB;
                                ram1_input   = write_data_APB;
                                we_ram1      = 1'b1;

                            end else if (selected_channel == 2'd1) begin
                                addr_to_ram2 = write_addr_APB;
                                ram2_input   = write_data_APB;
                                we_ram2      = 1'b1;

                            end else if (selected_channel == 2'd2) begin
                                addr_to_ram3 = write_addr_APB;
                                ram3_input   = write_data_APB;
                                we_ram3      = 1'b1;
                            end
                    end
                end
            //-----------------------------------------
            KERNEL_READ: begin
                    if (rd_knl_rq_i) begin
                        next_delayed_rd_handshake =1'b1;
                
                        addr_to_ram1 = burst_addr;
                        re_ram1      = 1'b1;
        
                        addr_to_ram2 = burst_addr;
                        re_ram2      = 1'b1;
            
                        addr_to_ram3 = burst_addr;
                        re_ram3      = 1'b1;

                        if (burst_cnt <= BURST_SIZE) begin
                            next_burst_cnt  = burst_cnt + 1;
                            next_burst_addr = burst_addr + 1;
                        end else begin
                            next_burst_cnt = 0;
                            next_delayed_rd_handshake = 1'b0;
                            next_burst_addr =KERNEL_BASE_ADDR;
                        end
                    end
            end
            //-----------------------------------------
            RAM_READ: begin
                    //re_ram1 = 1'b1; //TODO: this was on perma
                    //comb_re_wrapper   = 1'b1; 
                    //comb_burst_rd_handshake= 1'b1;  

                    if (burst_rd_rq_i) begin
                        next_delayed_rd_handshake = 1'b1;


                            enable_patch = 1'b0;
                            if (valid_patch) begin
                                addr_to_ram1 = patch_addr;
                                addr_to_ram2 = patch_addr;
                                addr_to_ram3 = patch_addr;

                                re_ram1 = 1'b1;
                                re_ram2 = 1'b1;
                                re_ram3 = 1'b1;
                            end
                            //-------------------------
                            if (burst_cnt <= BURST_SIZE) begin                     
                                /*//TODO: 
                                this needs to be deasserted on exact time or patch counter
                                keeps counting and wasting addresses
                                //TODO: 
                                But DONE_patch must be delayed or last address is generated and given to ram but not counter since done_patch drops
                                */
                                enable_patch = 1'b1;
                                next_burst_cnt = burst_cnt + 1;
                            end else if (burst_cnt < RA_RD_CYCLES) begin

                                /* it has to be < not <= to increment one last time
                                to meet exit condition from state but not an extra time to allow handshake to be deasserted at exit*/
                                next_burst_cnt = burst_cnt + 1;
                                
                            end else begin

                                next_burst_cnt = 0;
                                next_delayed_rd_handshake = 1'b0;
                            end
                            //-------------------------
                    end
            end

            //-----------------------------------------
            RAM_WRITE: begin
                //TODO:
                /*1 cycle is enough for a single ofm pixel.
                Condition to enter this state is wr_rq meaning it doenst need to be checked here.
                So its safe to immedately handshake.
                Handshake is combinational hence will be seen mid-cycle by CA.
                CA provides data and addr combi too so itll be seen here.
                All done in 1 clks.
                Should we register to make it safer? */
                
                if (!(read_cmd_APB && CA_finished_i)) begin
                    wr_handshake  = 1'b1;
                    we_ram4       = 1'b1;
                    addr_to_ram4  = wr_addr_CA;
                    ram4_input    = wr_data_CA;
                end
  
                //TODO:
                /*checking this condition is not necessary*/
                /*if (wr_rq_CA_i) begin
                end
                */
            end
            //-----------------------------------------
        endcase
    end

// ===================================================================================
//  Sequential Process
// ===================================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state         <= IDLE;
            burst_cnt          <= '0;
            burst_addr         <= KERNEL_BASE_ADDR;
            delayed_rd_handshake<=1'b0;
            result_counter     <= '0;
            selected_channel   <= 2'd0;
            delayed_re_ram4    <= 0;
            ry_valid           <= 0;

        end else begin
            curr_state         <= next_state;
            burst_cnt          <= next_burst_cnt;
            burst_addr         <= next_burst_addr;
            delayed_rd_handshake<=next_delayed_rd_handshake;
            result_counter      <= next_result_counter;
            selected_channel    <= next_selected_channel;
            delayed_re_ram4     <= next_delayed_re_ram4;
            ry_valid            <= next_ry_valid;

        end
    end
// ===================================================================================
//  Component instantiations
// ===================================================================================

    ram_wrapper ram_1 (
        .clk         (clk),
        .write_en    (we_ram1),
        .read_en     (re_ram1),
        .addr        (addr_to_ram1),
        .ram_data_in (ram1_input),
        .ram_data_out(ram1_output_i),
        .ry          ()
    );

    ram_wrapper ram_2 (
        .clk         (clk),
        .write_en    (we_ram2),
        .read_en     (re_ram2),
        .addr        (addr_to_ram2),
        .ram_data_in (ram2_input),
        .ram_data_out(ram2_output_i),
        .ry          ()
    );

    ram_wrapper ram_3 (
        .clk         (clk),
        .write_en    (we_ram3),
        .read_en     (re_ram3),
        .addr        (addr_to_ram3),
        .ram_data_in (ram3_input),
        .ram_data_out(ram3_output_i),
        .ry          ()
    );

    ram_wrapper ram_4 (
        .clk         (clk),
        .write_en    (we_ram4),
        .read_en     (re_ram4),
        .addr        (addr_to_ram4),
        .ram_data_in (ram4_input),
        .ram_data_out(ram4_output_i),
        .ry          (ry_i)
    );    

    patch_gen_conv patch_gen_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable_patch),
        .patch_addr (patch_addr),
        .zero_pad   (zero_pad),
        .valid      (valid_patch),
        .done_1_patch (done_1_patch)
    );

endmodule
