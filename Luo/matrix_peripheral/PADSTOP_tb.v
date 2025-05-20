`timescale 1ns / 1ps


module PADSTOP_tb;

    reg  clk;
    reg  rst_n;
    reg  start;
    reg  [7:0]  X_load;
    reg  [1:0]  P_sel;
    wire [8:0] P_out;
    wire input_load_en;
    /*
	wire [6:0] a1_reg;
	wire [6:0] a2_reg;
	wire [7:0] x1_reg;
	wire [7:0] x2_reg;*/
    
    PADSTOP PADSTOP_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .X_load(X_load),
        .P_sel(P_sel),
        .P_out(P_out),
        .input_load_en(input_load_en),
        .Xload_done(Xload_done)
       /* .a1_reg(a1_reg),
        .a2_reg(a2_reg),
        .x1_reg(x1_reg),
        .x2_reg(x2_reg)*/
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
    reg toggle;
    reg [7:0]   stim_ptr;
    reg [7:0]   base_ptr;
    
    initial begin
        $readmemb("D:/Desktop/ICP1/input_stimuli.txt", stimuli);
        stim_ptr = 0;
    end
    
reg loading;
always @(negedge clk) begin
    if (!rst_n) begin
        stim_ptr <= 0;
        base_ptr <= 32;
        loading <= 0;
        X_load <= 8'h00;
        P_sel <= 0;
        toggle <= 0;
    end else begin
        // stim_ptr �� base_ptr
        if (input_load_en) begin
            if (stim_ptr == base_ptr + 31) begin
                stim_ptr <= base_ptr; 
                base_ptr <= base_ptr + 32;
                loading <= 1;
            end else if (Xload_done == 1) begin
                stim_ptr <= base_ptr;
                loading <= 1;
            end else if (loading == 1) begin
                stim_ptr <= base_ptr + 1;
                loading <= 0;
            end else begin
                stim_ptr <= stim_ptr + 1;
            end
        end

        // X_load �� P_sel��toggle 
        if (input_load_en) begin
            if (stim_ptr < STIMULI_SIZE) begin
                if (Xload_done == 0) begin
                    X_load <= stimuli[stim_ptr];
                end
            end else begin
                X_load <= 8'h00;
            end
        end

        toggle <= ~toggle;
        if (toggle == 1'b0)
            P_sel <= P_sel;
        else
            P_sel <= P_sel + 1;
    end
end


endmodule
