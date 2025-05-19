`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/02 10:03:30
// Design Name: 
// Module Name: Multiplier_t
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module Multiplier_t;

    // Inputs
    reg clk;
    reg rst_n;
    reg input_load_en;
    reg AU_en;
    reg [7:0] X_load;

    // Outputs
    wire Xload_done;
    wire row_done;
    wire [15:0] P;

    // Instantiate the Unit Under Test (UUT)
    Multiplier uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .input_load_en(input_load_en), 
        .AU_en(AU_en),
        .X_load(X_load), 
        .Xload_done(Xload_done),
        .row_done(row_done),
        .P(P)
    );

    // Clock generation process
    always #5 clk = ~clk; // 100 MHz clock

   initial begin
        clk = 0;
        rst_n = 0;
        input_load_en = 0;
        AU_en = 0;
        #20;
        rst_n = 1;
        #10 input_load_en = 1;
        wait (Xload_done == 1);
        #10;
        input_load_en = 0;
        AU_en = 1;
    end
    
    
    localparam STIMULI_SIZE = 160;
    reg [7:0] stimuli [0:STIMULI_SIZE-1];
    integer   stim_ptr;
    
    initial begin
        $readmemb("D:/Desktop/ICP1/input_stimuli.txt", stimuli);
        stim_ptr = 0;
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stim_ptr <= 0;
            X_load   <= 8'h00;
        end
        else begin
            if (input_load_en) begin
                if (stim_ptr < STIMULI_SIZE) begin
                    X_load <= stimuli[stim_ptr];
                    stim_ptr <= stim_ptr + 1;
                end
                else begin
                    X_load <= 8'h00;
                end
            end
        end
    end
   

endmodule
