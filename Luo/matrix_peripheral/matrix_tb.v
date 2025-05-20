`timescale 1ns / 1ps


module matrix_tb;

    reg  clk;
    reg  rst_n;
    reg  start;
    reg  [7:0]  X_load;
    reg  [1:0]  P_sel;
    wire [17:0] P_out;
    wire input_load_en;
    
    matrixTOP matrixTOP_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .X_load(X_load),
        .P_sel(P_sel),
        .P_out(P_out),
        .input_load_en(input_load_en)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end
    
    initial begin
        start = 0;
        P_sel = 2'b00;
        wait(rst_n == 1);
        #30;
        start = 1;
        #3000;
    end
    
    localparam STIMULI_SIZE = 160;
    reg [7:0] stimuli [0:STIMULI_SIZE-1];
    integer   stim_ptr;
    
    initial begin
        $readmemb("D:/Xilinx/Project/MatrixMultiplier/input_stimuli.txt", stimuli);
        stim_ptr = 0;
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stim_ptr <= 0;
            X_load   <= 8'h00;
            P_sel <= 0;
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
            P_sel <= P_sel + 1;
        end
    end

endmodule
