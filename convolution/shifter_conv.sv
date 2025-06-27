`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

module shifter_conv (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  shift_en,         // Rotate one position
    input  logic                  shifter_write,    // Load one value into tail

    input  logic [DATA_WIDTH-1:0] shifter_in,       // Value to load
    output logic [DATA_WIDTH-1:0] shifter_out       // Always head value
);


    logic [DATA_WIDTH-1:0] shift_reg      [0:SHIFTER_DEPTH-1];
    logic [DATA_WIDTH-1:0] shift_reg_next [0:SHIFTER_DEPTH-1];

// ===================================================================================
//  register updates
// ===================================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < SHIFTER_DEPTH; i++) begin
                shift_reg[i] <= '0;
            end
        //-------------------------------------
        end else begin
            for (int i = 0; i < SHIFTER_DEPTH; i++) begin
                shift_reg[i] <= shift_reg_next[i];
            end
        end
    end

// ===================================================================================
//  combinational logic
// ===================================================================================
    always_comb begin
        // Default: hold values
        for (int i = 0; i < SHIFTER_DEPTH; i++) begin
            shift_reg_next[i] = shift_reg[i];
        end

        //--------------------------------------------
        if (shifter_write) begin
            // Load new value into tail (last entry), keep rest
            shift_reg_next[0] = shift_reg[1];
            shift_reg_next[1] = shift_reg[2];
            shift_reg_next[2] = shift_reg[3];
            shift_reg_next[3] = shift_reg[4];
            shift_reg_next[4] = shift_reg[5];
            shift_reg_next[5] = shift_reg[6];
            shift_reg_next[6] = shift_reg[7];
            shift_reg_next[7] = shift_reg[8];
            shift_reg_next[8] = shifter_in;
        

        //----------------------------------------------
        end else if (shift_en) begin
            // Rotate left (wrap around)
            shift_reg_next[0] = shift_reg[1];
            shift_reg_next[1] = shift_reg[2];
            shift_reg_next[2] = shift_reg[3];
            shift_reg_next[3] = shift_reg[4];
            shift_reg_next[4] = shift_reg[5];
            shift_reg_next[5] = shift_reg[6];
            shift_reg_next[6] = shift_reg[7];
            shift_reg_next[7] = shift_reg[8];
            shift_reg_next[8] = shift_reg[0];
        end
    end

// ===================================================================================
//  output logic
// ===================================================================================
    assign shifter_out = shift_reg[0];

endmodule
