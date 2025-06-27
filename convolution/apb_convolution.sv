// ======================================================
// APB Wrapper for top_file_convolution
// Fully structured with 4 clean separated processes
// - Sequential register update
// - Combinational control path
// - Combinational data path
// - Combinational output logic
// ======================================================

module apb_convolution #(
    parameter RAM_SIZE   = 1024,
    parameter ADDR_WIDTH = $clog2(RAM_SIZE),
    parameter DATA_WIDTH = 8
)(
    input  logic                  HCLK,
    input  logic                  HRESETn,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,
    input  logic [11:0]           PADDR,
    input  logic [31:0]           PWDATA,
    output logic [31:0]           PRDATA,
    output logic                  PREADY,
    output logic                  PSLVERR
);

    // ------------------------
    // Internal FSM Declaration
    // ------------------------
    typedef enum logic [2:0] {
        IDLE,
        WRITE_INIT,
        WRITE,
        APB_READ
    } apb_state_t;

    apb_state_t state, next_state;

    // TODO:
    /* Addr must be 12 bits from outside but we only use 10 bits PADDR [11:2]*/

    // ------------------------
    // Internal Register Declarations
    // ------------------------
    logic [DATA_WIDTH-1:0] wr_data_reg, next_wr_data;
    logic [ADDR_WIDTH-1:0] rd_burst_addr_reg, next_rd_burst_addr;
    //logic [ADDR_WIDTH-1:0] rd_addr_reg, next_rd_addr;
    //logic [ADDR_WIDTH-1:0] rd_addr_single;

    logic [ADDR_WIDTH-1:0] read_counter, next_read_counter;
    logic enable_ram4, next_enable_ram4;

    logic [ADDR_WIDTH-1:0] rd_addr_to_ram;

    logic data_latched, next_data_latched;
    
    logic input_mode, next_input_mode;
    logic input_cmd, next_input_cmd;

    logic kernel_mode, next_kernel_mode;
    logic kernel_cmd, next_kernel_cmd;

    //logic read_mode, next_read_mode;
    logic read_cmd, next_read_cmd;
    
    logic burst_rd_cmd, next_burst_rd_cmd;

    logic [11:0] wr_counter, next_wr_counter;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [1:0] wr_channel;

    logic valid_input_APB;
    logic write_en_APB;
    logic start_APB;

    logic [DATA_WIDTH-1:0] top_output;
    logic CA_finished;

    logic sw_wr_cmd; 
    assign sw_wr_cmd = (PSEL && PENABLE && PWRITE);

    // read by software

    //TODO: 
    /* in the above sofware initiates read but hasnt necessarily finished reading
    we make sure transaction is only finished when ram4 is ready meaning read has been completed. So:
        to get into read mode sw actually does a wr command to control register
        once asserted the addressing is done automatically here in a serial fasion.

        then sw attempts to read values:
        we can know when software attempts to read since it will do so by asserting ABP read protocol so we can wrap it into these signals here:

        sw assertes      sw_rd_init
        apb_conv asserts sw_rd_init after ram assertes ry
        now we can move on to next addr
    Must wait until software does an APB read before incrementing read addr*/
    logic ry_ram4;
    logic APB_ready_delayed, next_APB_ready_delayed;


    logic sw_rd_init; 
    assign sw_rd_init = (PSEL && PENABLE && !PWRITE);
    
    logic waiting_for_ram4, next_waiting_for_ram4;

    logic sw_read_done;
    assign sw_read_done = (PSEL && PENABLE && !PWRITE && PREADY);

    logic all_read_done, next_all_read_done;
    logic CA_reset_apb, next_CA_reset_apb;

    /* In APB, the master latches PRDATA only when PREADY = 1 during the access phase
    */

    logic data_write_pulse;
    assign data_write_pulse = (sw_wr_cmd && (PADDR[11:2] == 10'h000));

    // ======================================================
    // Sequential Process: Register Update ONLY
    // ======================================================
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            wr_data_reg     <= 0;
            //rd_addr_reg     <= 0;
            wr_counter      <= 0;
            input_mode      <= 0;
            kernel_mode     <= 0;
            //read_mode       <= 0;
            state           <= IDLE;
            data_latched    <= 0;
            read_counter    <= 0;
            enable_ram4      <= 0;
            burst_rd_cmd    <= 0;

            input_cmd       <= 0;
            kernel_cmd      <= 0;
            read_cmd        <= 0;
            waiting_for_ram4 <= 0;
            all_read_done    <= 0;
            CA_reset_apb     <=0;
            APB_ready_delayed <= 1'b0;

        end else begin
            wr_data_reg     <= next_wr_data;
            //rd_addr_reg     <= next_rd_addr;
            rd_burst_addr_reg<= next_rd_burst_addr;
            wr_counter      <= next_wr_counter;
            input_mode      <= next_input_mode;
            kernel_mode     <= next_kernel_mode;
            //read_mode       <= next_read_mode;
            state           <= next_state;
            data_latched    <= next_data_latched;
            read_counter    <= next_read_counter;
            enable_ram4     <= next_enable_ram4;
            burst_rd_cmd    <= next_burst_rd_cmd;
            waiting_for_ram4 <= next_waiting_for_ram4;

            input_cmd       <= next_input_cmd;
            kernel_cmd      <= next_kernel_cmd;
            read_cmd        <= next_read_cmd;
            all_read_done   <= next_all_read_done;
            CA_reset_apb    <= next_CA_reset_apb;
            APB_ready_delayed <= next_APB_ready_delayed;
        end
    end

    // ======================================================
    // APB Writes
    // ======================================================
    always_comb begin
        next_wr_data     = wr_data_reg;
        //next_rd_addr     = rd_addr_reg;
        
        next_input_mode   = input_mode;
        next_input_cmd = 0;

        next_kernel_mode   = kernel_mode ;
        next_kernel_cmd = 0;

        //next_read_mode   = read_mode;
        next_read_cmd = 0;

        next_burst_rd_cmd   = 0;

        /*software wrote somthing at one of the registers (pushed all 3 buttons).
        check address (cases) to see which register it was*/
        if (sw_wr_cmd) begin
            case (PADDR[11:2])
                //------------------------------------
                10'h000: begin // case: data reg
                    /*10'h000	0	0 × 4 = 0   → 0x000*/
                    next_wr_data     = PWDATA[7:0];

                end
                //------------------------------------
                /*10'h001: begin // case: rd addr reg
                    next_rd_addr        = PWDATA[ADDR_WIDTH-1:0];
                        /* enable read and at the same time give address. ram latches addres on rising edge. Provides data after*/
                //end 
                //------------------------------------
                10'h002: begin  // input_mode
                    /*10'h002	2	2 × 4 = 8   → 0x008*/
                    next_input_mode     = 1;
                    next_kernel_mode    = 0;
                    //next_read_mode      = 0;
                    next_input_cmd      = 1;
                end
                //------------------------------------
                10'h003: begin  // kernel_mode
                    /*10'h003	3	3 × 4 = 12  → 0x00C*/
                    next_input_mode     = 0;
                    next_kernel_mode    = 1;
                    //next_read_mode      = 0;
                    next_kernel_cmd     = 1;
                end
                //------------------------------------
                /*10'h004: begin  // read_mode set/clear
                    next_read_mode      = PWDATA[0]; // sw writes 1 to enable, 0 to disable
                    next_read_cmd       = 1;
                    next_input_mode     = 0;
                    next_kernel_mode    = 0;
                end*/
                //------------------------------------
                10'h008: begin 
                    /*10'h008	8	8 × 4 = 32  → 0x020*/
                    next_burst_rd_cmd = PWDATA[0];
                    next_input_mode     = 0;
                    next_kernel_mode    = 0;
                    //next_read_mode      = 0;
                end
                //------------------------------------
            endcase
        end
    end

    // ======================================================
    // APB Slave Output Logic
    // - PREADY asserted only when data is ready for read
    // - For write: slave doesn't stall, completes in 1 cycle
    // ======================================================
    always_comb begin
        PRDATA  = 32'd0;
        PREADY  = 1'b0;
        PSLVERR = 1'b0;

        // Read from controller RAM (RAM4)
        if (sw_rd_init) begin

            // if read is attempted check which register is being read
            case (PADDR[11:2])

                // --------------------------------------------
                10'h005: begin // dedicated output register
                    /*10'h005	5	5 × 4 = 20 → 0x014*/
                    if (APB_ready_delayed) begin  
                        PRDATA = {24'd0, top_output};
                        PREADY = 1'b1;
                    end
                end

                // --------------------------------------------
                10'h006: begin // CA status register
                    /*10'h006	6	6 × 4 = 24  → 0x018*/
                    PRDATA = {31'd0, CA_finished};
                    PREADY = 1'b1;
                end

                // --------------------------------------------
                10'h007: begin // all read done flag for software
                    /*10'h007	7	7 × 4 = 28  → 0x01C*/
                    PRDATA = {31'd0, all_read_done};
                    PREADY = 1'b1;
                end
                
                // --------------------------------------------
                default: begin
                    PRDATA = 32'd0;
                    PSLVERR = 1'b1; // invalid address
                end
            endcase
        // ------------------------------
            end else if (sw_wr_cmd) begin
                PREADY = 1'b1; // all writes complete in 1 cycle
            end
    end
    // ======================================================
    // FSM Next State Logic
    // ======================================================
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if      (input_cmd || kernel_cmd)
                        next_state = WRITE_INIT;

                /*else if (read_mode && CA_finished)
                        next_state = READ;*/

                else if (burst_rd_cmd && CA_finished)
                        next_state = APB_READ;
                
            end
            //----------------------------------
            WRITE_INIT: begin
                next_state = WRITE; 
            end
            //----------------------------------
            WRITE: begin
                if ((input_mode && wr_counter == 12'd2352) ||
                    (kernel_mode && wr_counter == 12'd26 && data_latched)) begin
                    next_state = IDLE;
                end
            end

            //----------------------------------
            /*READ: begin
                if (read_mode == 1'b0)
                    next_state = IDLE;
            end*/
            //----------------------------------
            APB_READ: begin
                if (all_read_done)
                    next_state = IDLE;
            end
            //----------------------------------
            default: next_state = IDLE;
        endcase
    end

    // ======================================================
    // Address and Channel Generation
    // ======================================================
    always_comb begin
            
            wr_addr    = {ADDR_WIDTH{1'b0}}; // Default address

            if (input_mode == 1'b1) begin
                wr_addr = wr_counter % 784;

            end else if (kernel_mode == 1'b1) begin
                wr_addr = (wr_counter % 9) + 784; // Kernel address offset
            end
        end

    // ======================================================
    // Combinational Datapath Logic
    // ======================================================
    always_comb begin
        // Default values
        valid_input_APB     = 0;
        write_en_APB        = 0;
        start_APB           = 0;
        next_wr_counter     = wr_counter;
        next_data_latched   = data_latched;
        next_rd_burst_addr  = rd_burst_addr_reg;
        next_read_counter   = read_counter;
        next_enable_ram4     = 0;
        wr_channel          = 2'd0;
        next_waiting_for_ram4 = 0;
        next_all_read_done = all_read_done;
        next_CA_reset_apb  = 1'b0;

        
        // read address
        //rd_addr_to_ram = (state == APB_READ) ? rd_burst_addr_reg : rd_addr_single;
        rd_addr_to_ram = rd_burst_addr_reg; 

        case (state)

            IDLE: begin 
                next_wr_counter    = 0;
                next_data_latched  = 0;
                next_read_counter  = 0;
                //next_all_read_done = 0;
            end
            //-----------------------------
            WRITE_INIT: begin

                wr_channel   = 2'd0;
                write_en_APB = 1'b1; // assert write_en and channel only    
               /*if (data_write_pulse) begin 
                next_wr_counter = wr_counter-1;
               end   */         
               next_all_read_done = 0;
            end
            //-----------------------------
            WRITE: begin
                        
                if (data_write_pulse && !data_latched) begin
                    next_data_latched = 1'b1;
                end

                if (data_latched) begin 

                        next_data_latched  = 0;
                        valid_input_APB = 1'b1;

                        next_wr_counter = wr_counter + 1;

                        if (input_mode == 1'b1) begin
                                //TODO:
                            /* we need to change channel on the last data of each channel not on the first data of new 
                            channel. Also change these to be scalable rn they are hardcoded*/
                                //------------------------------------
                                if (wr_counter == 12'd783) begin
                                    wr_channel      = 2'd1;
                                    write_en_APB    = 1'b1;
                                //------------------------------------
                                end else if (wr_counter == 12'd1567) begin
                                    wr_channel      = 2'd2;
                                    write_en_APB    = 1'b1;
                                end  
                        //------------------------------------                      
                        end else if (kernel_mode == 1'b1) begin
                                //------------------------------------
                                if (wr_counter == 12'd8) begin
                                    wr_channel      = 2'd1;
                                    write_en_APB    = 1'b1;
                                //------------------------------------
                                end else if (wr_counter == 12'd17) begin
                                    wr_channel      = 2'd2;
                                    write_en_APB    = 1'b1;
                                end 
                        //------------------------------------
                        if (wr_counter + 1 == 12'd27) begin
                            start_APB = 1'b1;
                        end
                        end
                    end
                end

            //-----------------------------
            /*READ: begin
                next_enable_ram4 = 1;
                rd_addr_single = rd_addr_reg; // Use user-specified address
                //TODO:
                /*
                since addr is delayed by a register here so should read command be since they are sent togther to ram in the ram controller. I was sending read command too early sending an invalid x address which was causing all subsequent values to become x not just the first one*/
            //end 
            
            //-----------------------------
            APB_READ: begin
                if (read_counter < 10'd785) begin
                        next_rd_burst_addr = read_counter; 

                        // make sure data is read by sw before incr
                        if (sw_rd_init && !waiting_for_ram4) begin
                            next_waiting_for_ram4 = 1;
                            next_enable_ram4 = 1; 
                        end
                        
                        if (waiting_for_ram4) begin
                            next_APB_ready_delayed= 1;
                        end

                        if (sw_read_done) begin
                                // set read addr
                                // incr addr and counter
                            next_read_counter = read_counter + 1; 
                            // assert read mode to ram controller
                            next_waiting_for_ram4 = 0;
                            next_APB_ready_delayed= 0;
                        end

                end else begin
                    next_read_counter = 0;
                    next_all_read_done = 1'b1;
                    next_CA_reset_apb  = 1'b1;
                end
            end
            //-----------------------------
            default: begin
                // Do nothing in IDLE
            end
        endcase
    end

    // ======================================================
    // Inst top_file_convolution
    // ======================================================
    top_file_convolution u_top (
        .clk                (HCLK),
        .rst_n              (HRESETn),
        .start_APB          (start_APB),
        .channel_top        (wr_channel),
        .write_en_APB       (write_en_APB),
        .valid_input_APB    (valid_input_APB),
        .write_addr_APB     (wr_addr),
        .write_data_APB     (wr_data_reg),
        .ry_APB             (ry_ram4),
        .read_APB_data_top  (top_output),
        .read_cmd_APB_top   (enable_ram4),
        .read_apb_addr_top  (rd_addr_to_ram),
        .CA_finished        (CA_finished),
        .CA_reset_top           (CA_reset_apb)
    );

endmodule

    /*
    clk 1: 
    rd_addr_reg <= PWDATA[ADDR_WIDTH-1:0];
    apb_rd_en   <= 1;
    rd_request_sent <=1;  

    clk2:
    ram output available mid cycle

    clk 3:
    ram output is latched into rd_data_reg

    so far no read attempt has been made from any apb registers*/


/*
    Great question — read_request_sent was used in your original code to track when a read operation had just been issued, so that a two-cycle delay pipeline could be triggered to latch the RAM output into a register (since your RAM has 2-cycle latency).
    Why It Disappeared in the New apb_convolution.sv

    In this new architecture:

    apb_convolution is no longer responsible for tracking read latency.
    */



    /*
    both values are hex,
    Address	PADDR[11:2]	Register	Description
   decimal: 0   0x000	10'h000	wr_data_reg	Write data (1 byte)
   decimal: 4   0x004	10'h001	wr_addr_reg	Write address
   decimal: 8   0x008	10'h002	rd_addr_reg	Read address
   decimal: 12  0x00C	10'h003	wr_channel	Select RAM to write
   decimal: 20  0x014	10'h005	rd_data_reg	Read data
   decimal: 24  0x018	10'h006	ram_ready	Read ready flag (1 = data valid)*/              


      // ----------------------------
    // APB Write Handling
    // ----------------------------

    /*Handles APB write transactions to different internal control registers.
      1. Decodes which register is targeted by PADDR.
      2. Latches data for address/data/registers.
      3. Triggers single-cycle enable for RAM controller.
        Write occurs only when both data and address have been latched.*/

/*
//TODO: filling ram protocol
        1. assert write_en and channel at the same time. This selects write channel.
        2. assert valid data, data and addr for each input.
            this means we change channels 6 times:
            3 for filling ram with inputs and 3 for filling ram with weights.
            wr channle for inputs and corresponding weights must be the same. Order doesnt matter otherwise.
        3. assert START and CA will do the rest. APB write is complete    
        */

/*
//TODO: read protocol
        must only happen if CA_finished is asserted so we can expose that to APB
        once that happens ram4 will be directly accessible by apb_wrapper
        */


/*we dont actually need to have a complicated mux
we can have two registers one for inputs and one for kernel
software asserts those when writing to either
so sw asserts input_reg then sends all inputs
wrapper must automatically switch rams every 784
then software asserts kernel_reg
wrapper swtiches channel every 9 data
*/

/*wait this is wrong sw does not send any addresses either
wrapper must takes care of that so software only sends these input_mode, kernel_mode, read_mode, input_data, read_addr, start
make these changes
in idle state we check for these:
input_mode, kernel mode, if either is true we go into write state and in idle state assert channel and write_enable
also check for read_mode, if CA finished is asserted we go into read state

we only latch input data and read addr from outside

write_state:
here we do several tasks
for all datas we only assert these:
valid, and data and addr must be asserted at the same time
every 784 addresses write_en is assreted together with new channel but no data is written */

//TODO:
/* some signals are on before and after a certain event. If we want to use them for handshake but make sure we dont check them before the event we make an intermediate signal which goes high after event is initiated. Once handshake is done that signal is deasserted. Now even though the signal of interest is high we wont check it until an even occurs. Good for ry of ram4 when we want to wait for read results but ry is high even when no read is called hence ry cannot be used directly as handshake for control signals.*/
