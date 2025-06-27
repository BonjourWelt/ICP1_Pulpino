`timescale 1ns / 1ps

`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

// ======================================================
// Testbench for patch_gen_conv
// Generates all 28x28 patches × 9 addresses = 7056 total
// ======================================================

module patch_gen_conv (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   enable,              // Enable address generation

    output logic [ADDR_WIDTH-1:0]  patch_addr,          // Single address output (shared across channels)
    output logic                   zero_pad,            // Single zero padding flag (shared across channels)
    output logic                   valid,               // 1 when address is valid
    output logic                   done_1_patch         // 1 when 9 addresses complete
);

    // Internal registers
    logic [5:0] patch_row_reg, patch_row_next;
    logic [5:0] patch_col_reg, patch_col_next;

    logic [3:0] counter_reg, counter_next;
    logic [ADDR_WIDTH-1:0] addr_next;

    logic zero_pad_reg, zero_pad_next;
    logic valid_reg, valid_next;
    logic done_reg, next_done;
    logic [2:0] i, j;
    logic signed [6:0] real_row, real_col;

    // TODO: delete later : Debug counter
    logic [15:0] debug_count_reg, debug_count_next;

    // ======================================================
    // Sequential Register Update
    // ======================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            patch_row_reg <= 6'd0;
            patch_col_reg <= 6'd0;
            counter_reg   <= 4'd0;
            zero_pad_reg  <= 1'b0;
            valid_reg     <= 1'b0;
            debug_count_reg<= 1'b0;
            done_reg      <= 1'b0;
        end else begin
            patch_row_reg <= patch_row_next;
            patch_col_reg <= patch_col_next;
            counter_reg   <= counter_next;
            zero_pad_reg  <= zero_pad_next;
            valid_reg     <= valid_next;
            debug_count_reg<= debug_count_next;
            done_reg      <= next_done;
        end
    end

    // ======================================================
    // Control Path Logic
    // ======================================================
    always_comb begin
        patch_row_next = patch_row_reg;
        patch_col_next = patch_col_reg;
        counter_next   = counter_reg;

        if (enable == 1'b1) begin
            if (counter_reg < BURST_SIZE) begin
                counter_next = counter_reg + 1;
            end

            if (counter_reg == BURST_SIZE) begin
                // Advance patch window for next trigger
                if (patch_col_reg + 1 < IFM_WIDTH) begin
                    patch_col_next = patch_col_reg + 1;
                end else begin
                    patch_col_next = 0;
                    if (patch_row_reg + 1 < IFM_HEIGHT) begin
                        patch_row_next = patch_row_reg + 1;
                    end else begin
                        patch_row_next = 0;
                    end
                end
                counter_next = 0;
            end
        end
    end

    // ======================================================
    // Datapath Logic
    // ======================================================
        always_comb begin
            //zero_pad_next = 1'b0; 

            i = counter_reg / 3;
            j = counter_reg % 3;

            real_row = patch_row_reg + i - 1;
            real_col = patch_col_reg + j - 1;

            if ((real_row < 0 || real_row >= IFM_HEIGHT ||
                real_col < 0 || real_col >= IFM_WIDTH) && enable == 1'b1) begin
                addr_next = '0;
                zero_pad_next = 1'b1;
                
            end else begin
                addr_next = real_row * IFM_WIDTH + real_col;
                zero_pad_next = 1'b0;
            end
        end
   
   
    /*always_comb begin
        i = counter_reg / 3;
        j = counter_reg % 3;

        addr_next = (patch_row_reg * IFM_WIDTH + patch_col_reg) + (i * IFM_WIDTH + j);

        if ((patch_row_reg + i) >= IFM_HEIGHT || (patch_col_reg + j) >= IFM_WIDTH) begin
            zero_pad_next = 1'b1;
        end else begin
            zero_pad_next = 1'b0;
        end
    end*/

    // ======================================================
    // Output Logic
    // ======================================================

    always_comb begin
        patch_addr = addr_next;
        zero_pad   = zero_pad_reg;
        //valid      = valid_reg;
        valid_next = 1'b0;
        debug_count_next  = debug_count_reg;

        done_1_patch = done_reg;

        if (enable == 1'b1 && counter_reg < BURST_SIZE) begin
            //TODO:
            /*delaying valid causes the first address to be missed by ram because it only accepts addresses when valid is up*/
            //valid_next = 1'b1;
            valid= 1'b1;
            debug_count_next = debug_count_reg + 1;
        end else begin
            valid= 1'b1;
            //valid_next = 1'b0;
        end

        if (enable == 1'b1 && counter_reg == BURST_SIZE) begin
            //TODO:
            /*must be delayed but cant use cycles since enable depedns on cycles so we regiter it*/
            //done_1_patch = 1'b1;
            next_done = 1'b1;
        end else begin
            //done_1_patch = 1'b0;
            next_done = 1'b0;
        end
    end

endmodule

/*
//TODO: 
since address and zero pad are generated instantly but ram produces with a clk delay to emulated the ram behavior when we reach a pad we also have to output it with a clock delay.
otherwise a zero_pad falls on top of a legit ram output sometimes.

Now:
clk 0: rd_rq recieved
clk 1: patch is enabled and next cycle has a real address which goes to ram
clk 2: rd_handshake and patch_valid are asserted 

zero padding is delayed by a cycle now, it masks a legit next address but thats ok since it wont mask that addresses output which comes next cycle
*/

