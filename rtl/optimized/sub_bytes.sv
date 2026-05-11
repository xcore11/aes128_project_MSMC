`timescale 1ns/1ps
`default_nettype none

/*
 * ============================================================
 * File        : sub_bytes.sv
 * Description : AES-128 shared-resource SubBytes transformation
 *
 * Function:
 *   Applies the AES S-box to all 16 bytes of the 128-bit AES
 *   state using only one shared S-box.
 *
 * Optimized design choice:
 *   - Baseline SubBytes uses 16 parallel S-box instances.
 *   - This optimized version uses only one S-box.
 *   - The single S-box is reused across 16 clock cycles.
 *
 * Area optimization:
 *   - Baseline:
 *       16 S-boxes, one-cycle SubBytes.
 *
 *   - Optimized:
 *       1 S-box, sixteen-cycle SubBytes.
 *
 * Trade-off:
 *   - Area is reduced significantly because duplicated S-box
 *     hardware is removed.
 *   - Latency increases because bytes are substituted one at a time.
 *
 * Control interface:
 *   start : Pulse high for one clock cycle to begin SubBytes.
 *   done  : Pulses high for one clock cycle when state_out is valid.
 *
 * Notes:
 *   - In the optimized project, the sbox module should be the
 *     fixed Boolean S-box implementation.
 *   - The AES core must wait for done before using state_out.
 * ============================================================
 */

module sub_bytes
(
    // System clock.
    input  logic         clk,

    // Active-low asynchronous reset.
    input  logic         reset_n,

    // Internal start signal from aes_core_optimized.
    input  logic         start,

    // AES state before SubBytes.
    input  logic [127:0] state_in,

    // AES state after SubBytes.
    output logic [127:0] state_out,

    // One-clock pulse when state_out is valid.
    output logic         done
);

    /*
     * FSM states.
     *
     * S_IDLE:
     *   Waits for start.
     *
     * S_RUN:
     *   Uses one S-box to substitute one byte per clock cycle.
     *
     * S_CALC:
     *   Pulses done high and returns to idle.
     */
    typedef enum logic [1:0]
    {
        S_IDLE,
        S_RUN,
        S_CALC
    } state_t;

    // Current FSM state.
    state_t state;

    /*
     * Latched input state.
     *
     * state_in is captured when start is accepted, so the input
     * does not need to remain stable during the 16-cycle operation.
     */
    logic [127:0] state_reg;

    /*
     * Temporary output register.
     *
     * Each substituted byte is written into this register one at a time.
     * When all 16 bytes are completed, this register is copied to state_out.
     */
    logic [127:0] sub_bytes_reg;

    /*
     * byte_index selects which byte is currently sent into the shared S-box.
     *
     * 0  -> state_reg[7:0]
     * 1  -> state_reg[15:8]
     * ...
     * 15 -> state_reg[127:120]
     */
    logic [3:0] byte_index;

    // Input to the single shared S-box.
    logic [7:0] sbox_in;

    // Output from the single shared S-box.
    logic [7:0] sbox_out;

    /*
     * Single shared S-box instance.
     *
     * In the optimized design, this should be your Boolean S-box,
     * not the baseline lookup-table S-box.
     */
    sbox u_shared_sbox
    (
        .in_byte  (sbox_in),
        .out_byte (sbox_out)
    );

    /*
     * Select one byte from state_reg for the shared S-box.
     *
     * The selected byte depends on byte_index.
     */
    always_comb begin
        case (byte_index)
            4'd0:    sbox_in = state_reg[7:0];
            4'd1:    sbox_in = state_reg[15:8];
            4'd2:    sbox_in = state_reg[23:16];
            4'd3:    sbox_in = state_reg[31:24];
            4'd4:    sbox_in = state_reg[39:32];
            4'd5:    sbox_in = state_reg[47:40];
            4'd6:    sbox_in = state_reg[55:48];
            4'd7:    sbox_in = state_reg[63:56];
            4'd8:    sbox_in = state_reg[71:64];
            4'd9:    sbox_in = state_reg[79:72];
            4'd10:   sbox_in = state_reg[87:80];
            4'd11:   sbox_in = state_reg[95:88];
            4'd12:   sbox_in = state_reg[103:96];
            4'd13:   sbox_in = state_reg[111:104];
            4'd14:   sbox_in = state_reg[119:112];
            4'd15:   sbox_in = state_reg[127:120];
            default: sbox_in = 8'h00;
        endcase
    end

    /*
     * Sequential shared SubBytes operation.
     */
    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin
            state         <= S_IDLE;
            state_reg     <= 128'h0;
            sub_bytes_reg <= 128'h0;
            byte_index    <= 4'd0;
            state_out     <= 128'h0;
            done          <= 1'b0;
        end

        else begin
            // done is cleared by default so it behaves as a one-clock pulse.
            done <= 1'b0;

            case (state)

                S_IDLE: begin
                    if (start) begin
                        // Latch the input AES state.
                        state_reg <= state_in;

                        // Clear output accumulation register.
                        sub_bytes_reg <= 128'h0;

                        // Start from byte 0.
                        byte_index <= 4'd0;

                        // Begin byte-by-byte S-box substitution.
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    /*
                     * Store the current S-box output into the correct byte
                     * position of sub_bytes_reg.
                     *
                     * Because the S-box is combinational, sbox_out corresponds
                     * to the byte selected by byte_index in the same cycle.
                     */
                    case (byte_index)

                        4'd0: begin
                            sub_bytes_reg[7:0] <= sbox_out;
                            byte_index         <= 4'd1;
                        end

                        4'd1: begin
                            sub_bytes_reg[15:8] <= sbox_out;
                            byte_index          <= 4'd2;
                        end

                        4'd2: begin
                            sub_bytes_reg[23:16] <= sbox_out;
                            byte_index           <= 4'd3;
                        end

                        4'd3: begin
                            sub_bytes_reg[31:24] <= sbox_out;
                            byte_index           <= 4'd4;
                        end

                        4'd4: begin
                            sub_bytes_reg[39:32] <= sbox_out;
                            byte_index           <= 4'd5;
                        end

                        4'd5: begin
                            sub_bytes_reg[47:40] <= sbox_out;
                            byte_index           <= 4'd6;
                        end

                        4'd6: begin
                            sub_bytes_reg[55:48] <= sbox_out;
                            byte_index           <= 4'd7;
                        end

                        4'd7: begin
                            sub_bytes_reg[63:56] <= sbox_out;
                            byte_index           <= 4'd8;
                        end

                        4'd8: begin
                            sub_bytes_reg[71:64] <= sbox_out;
                            byte_index           <= 4'd9;
                        end

                        4'd9: begin
                            sub_bytes_reg[79:72] <= sbox_out;
                            byte_index           <= 4'd10;
                        end

                        4'd10: begin
                            sub_bytes_reg[87:80] <= sbox_out;
                            byte_index           <= 4'd11;
                        end

                        4'd11: begin
                            sub_bytes_reg[95:88] <= sbox_out;
                            byte_index           <= 4'd12;
                        end

                        4'd12: begin
                            sub_bytes_reg[103:96] <= sbox_out;
                            byte_index            <= 4'd13;
                        end

                        4'd13: begin
                            sub_bytes_reg[111:104] <= sbox_out;
                            byte_index             <= 4'd14;
                        end

                        4'd14: begin
                            sub_bytes_reg[119:112] <= sbox_out;
                            byte_index             <= 4'd15;
                        end

                        4'd15: begin
                            sub_bytes_reg[127:120] <= sbox_out;
                            byte_index             <= 4'd0;

                            // All 16 bytes have been substituted.
                            state <= S_CALC;
                        end

                        default: begin
                            byte_index <= 4'd0;
                            state      <= S_IDLE;
                        end

                    endcase
                end

                S_CALC: begin
                    /*
                     * Register the completed SubBytes result.
                     *
                     * After this clock edge:
                     *   - state_out is valid.
                     *   - done is high for one clock cycle.
                     */
                    state_out <= sub_bytes_reg;
                    done      <= 1'b1;

                    // Return to idle and wait for the next start pulse.
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule

`default_nettype wire