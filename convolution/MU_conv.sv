`include "conv_defines_pkg.sv"
import conv_defines_pkg::*;

// ======================================================
// Multiply Unit (MU) with Dynamic Patch Input
// 3-process FSM + separate output logic
// Expanded to use case-statements for FSM and datapath
// ======================================================


module MU_conv 
(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  MU_start,       // start signal
    input  logic [DATA_WIDTH-1:0] patch_in,       // patch input (1 per cycle)
    input  logic [DATA_WIDTH-1:0] kernel_in,      // kernel input (1 per cycle)
    output logic                  done,           // goes high when computation is complete
    input  logic                  wr_handshake_i,
    output logic [DATA_WIDTH-1:0] MU_ofm          // output (1 pixel, saturated)
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE,
        MULT_ACCUM,
        WAIT,
        DONE
    } state_t;

    state_t state, next_state;

    // Registers
    logic [3:0] MU_counter, next_MU_counter;
    logic [SUM_WIDTH-1:0] accum, next_accum;
    logic [SUM_WIDTH-1:0] MU_temp_result;
    logic done_i;

    // ======================================================
    // Sequential Process: Registers Only
    // ======================================================
    always_ff @(posedge clk or negedge rst) begin

        if (!rst == 1'b1) begin
            state        <= IDLE;
            MU_counter   <= 4'd0;
            accum        <= '0;
        //--------------------------------
        end else begin
            state        <= next_state;
            MU_counter   <= next_MU_counter;
            accum        <= next_accum;
        end
    end

    // ======================================================
    // Combinational Control Path
    // ======================================================
    always_comb begin
        
        next_state = state;
        //----------------------------------
        case (state)

            //----------------------------------
            IDLE: begin
                if (MU_start == 1'b1) begin
                    next_state = MULT_ACCUM;
                end
            end

            //----------------------------------
            MULT_ACCUM: begin
                if (MU_counter == BURST_SIZE-1) begin
                    next_state = WAIT;
                end
            end

            //----------------------------------
            WAIT: begin
                next_state = DONE;
            end

            //----------------------------------
            DONE: begin
                //TODO:
                /* we are done once data is written to ram not when
                we are done calculating*/
                if (wr_handshake_i == 1'b1) begin
                    next_state = IDLE;
                end
            end

        endcase
    end

    // ======================================================
    // Combinational Data Path
    // ======================================================
    always_comb begin
        
        MU_temp_result     = '0; 
        next_MU_counter = MU_counter;
        next_accum      = accum;
        done_i            = 1'b0;
        //----------------------------------
        case (state)

            //----------------------------------
            IDLE: begin
                next_MU_counter = 4'd0;
                next_accum     = '0;
                /* after done state we end up here.
                accum turns 0 next which is combinationally attached to output
                so we have 1 clks after done to retrieve output*/
                
                if (MU_start) begin
                    MU_temp_result  = patch_in * kernel_in;
                    next_accum      = accum + MU_temp_result;
                end
            end
            //----------------------------------
            MULT_ACCUM: begin
                MU_temp_result  = patch_in * kernel_in;
                next_MU_counter = MU_counter + 1;
                next_accum      = accum + MU_temp_result;
            end

            //----------------------------------
            WAIT: begin
                // No datapath updates
            end

            //----------------------------------
            DONE: begin
                done_i = 1'b1;
                if (wr_handshake_i == 1'b1) begin
                    next_accum = 0;
                end
            //once done is asserted output is valid
                
            end

        endcase
    end

    // ======================================================
    // Output and local saturation Logic
    // ======================================================
    always_comb begin

        MU_ofm = '0; /* since this is combinational I think this only triggers
        when ofm or accum change which doenst happen on IDLE state*/

        if (accum > 8'd255) begin
            MU_ofm = 8'd255;

        end else begin
            MU_ofm = accum[7:0];

        end
    end
    //-------------------------
    assign done = done_i;
    //-------------------------

endmodule


/*
# ==============================================================================
# Convolution Accelerator - MU Design and Patch Indexing Discussion WAITmary
# ==============================================================================

# This discussion focused on the design and timing of the Multiply Unit (MU)
# subsystem for a 3x3 convolution accelerator with 28x28x3 input feature map (IFM)
# and zero padding. Each MU is composed of three parts: multiplier, accumulator,
# and WAITmer. All values are 8-bit unsigned fixed-point (0–255) with saturation.

# ----------------------
# MU Timing Consideration
# ----------------------
# Each MU processes one 3x3 patch over 9 clock cycles (1 value per cycle),
# followed by 1 additional cycle to WAIT the 3 final MU outputs into a single OFM value.
# This results in one OFM pixel every 10 cycles.

# RAM delivers data at a max rate of 1 value per clock per RAM. For 3 input channels
# (e.g., RGB), we asWAITe 3 RAMs are used in parallel. Even so, fetching 9 patch values
# per channel (~27 values total) requires ~10–11 clock cycles due to latency between
# request and data availability. Hence, **3 MU units are sufficient to saturate RAM**,
# and adding more would not improve throughput.

# Thus, duplicating MUs or using ping-pong MU banks (e.g., 3 reading, 3 computing)
# is unnecessary unless RAMs can be made faster or deeper parallelism is introduced.

# --------------------------
# Patch Index Generation Logic
# --------------------------
# Patch index generation must occur before RAM reads. There were two options considered:

# 1. CA (Convolution Accelerator) generates indices:
#    - Recommended and selected approach.
#    - CA tracks sliding window positions using row and column counters.
#    - Base address is computed via:
#         base_addr = patch_row * IFM_WIDTH + patch_col
#    - The 9 patch addresses are generated by:
#         addr[i][j] = base_addr + i * IFM_WIDTH + j
#       for i, j in [0,2]
#    - These are stored in:
#         reg [ADDR_WIDTH-1:0] patch_addrs [0:8];
#    - Then sent one-per-cycle to the RAM controller.

# 2. RAM Controller generates indices:
#    - Rejected because it would duplicate convolution geometry logic and make the
#      controller less reusable.

# We also considered hardcoding all patch indices as a ROM-like table:
#     reg [9*ADDR_WIDTH-1:0] patch_indices_table [0:NUM_PATCHES-1];
# but rejected this due to inflexibility and register usage cost, especially if IFM
# size changes in future designs.

# --------------------------
# FSM Structure Recommendation
# --------------------------
# The CA FSM should follow a clean 3-process model and include:
#   - STATE_INDEX_GEN: compute the 9 patch indices and store them
#   - STATE_BURST_READ: coordinate RAM reads using those indices
#   - STATE_COMPUTE: MUs operate for 9 cycles
#   - STATE_WAIT: one cycle to add MU outputs and saturate if > 255
#   - STATE_WRITE: write OFM result to output RAM
#   - STATE_NEXT: update patch position (e.g., move right or down)

# --------------------------
# Saturation Logic for Output
# --------------------------
# Output value saturation is done during WAIT state:
#     assign saturated_WAIT = (WAIT > 8'd255) ? 8'd255 : WAIT;

# --------------------------
# Final Recommendations
# --------------------------
# - Use only 3 MUs (1 per input channel)
# - Generate patch indices dynamically in CA
# - Store 9 addresses per patch and drive them to RAM
# - Avoid over-provisioning MUs unless RAM speed increases
# - Structure FSM with a dedicated state for index generation
#   and clean separation of control, datapath, and register updates

# ==============================================================================
*/