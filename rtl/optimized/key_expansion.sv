`timescale 1ns/1ps
`default_nettype none

/*
 * ============================================================
 * File        : key_expansion.sv
 * Description : AES-128 shared-resource key expansion
 *
 * Function:
 *   Generates the next 128-bit AES round key using only one
 *   shared S-box.
 *
 * Optimized design choice:
 *   - Baseline key expansion uses four S-boxes in parallel.
 *   - This optimized version uses one S-box across four cycles.
 *   - This reduces hardware area, but key expansion now takes
 *     multiple clock cycles.
 *
 * Control interface:
 *   start : Pulse high for one clock cycle to begin key expansion.
 *   done  : Pulses high for one clock cycle when key_out is valid.
 *
 * AES-128 key schedule:
 *
 *   key_in = {w0, w1, w2, w3}
 *
 *   temp = SubWord(RotWord(w3)) XOR Rcon
 *
 *   w4 = w0 XOR temp
 *   w5 = w1 XOR w4
 *   w6 = w2 XOR w5
 *   w7 = w3 XOR w6
 *
 *   key_out = {w4, w5, w6, w7}
 *
 * Notes:
 *   - This module is sequential because one S-box is reused.
 *   - The AES core must wait for done before using key_out.
 *   - In the optimized project, the sbox module should be the
 *     fixed Boolean S-box implementation.
 *   - done is asserted directly in S_CALC to avoid an extra
 *     S_DONE cycle.
 * ============================================================
 */

module key_expansion
(
    // System clock.
    input  logic         clk,

    // Active-low asynchronous reset.
    input  logic         reset_n,

    // Internal start signal from aes_core_optimized.
    // Pulse high for one clock cycle to begin generating the next round key.
    input  logic         start,

    // Current 128-bit AES round key.
    input  logic [127:0] key_in,

    // Current AES round constant.
    input  logic [7:0]   rcon_byte,

    // Generated next 128-bit AES round key.
    output logic [127:0] key_out,

    // One-clock pulse when key_out is valid.
    output logic         done
);

    /*
     * FSM states.
     *
     * S_IDLE:
     *   Waits for start.
     *
     * S_SUBWORD:
     *   Reuses one S-box to substitute one byte of RotWord(w3)
     *   per clock cycle.
     *
     * S_CALC:
     *   Computes w4, w5, w6, and w7 after all four SubWord bytes
     *   have been generated. It also pulses done high when key_out
     *   is registered.
     */
    typedef enum logic [1:0]
    {
        S_IDLE,
        S_SUBWORD,
        S_CALC
    } state_t;

    // Current FSM state.
    state_t state;

    /*
     * Latched current key words.
     *
     * These registers capture key_in when start is accepted.
     * This means key_in does not need to remain stable while the
     * module is processing the key expansion.
     */
    logic [31:0] w0_reg;
    logic [31:0] w1_reg;
    logic [31:0] w2_reg;
    logic [31:0] w3_reg;

    // Latched Rcon byte for the current key expansion operation.
    logic [7:0] rcon_reg;

    /*
     * rot_word_reg stores RotWord(w3).
     *
     * If:
     *   w3 = {a0, a1, a2, a3}
     *
     * Then:
     *   rot_word_reg = {a1, a2, a3, a0}
     */
    logic [31:0] rot_word_reg;

    /*
     * sub_word_reg stores SubWord(RotWord(w3)).
     *
     * Since this optimized version uses only one S-box, the four
     * substituted bytes are written into this register one byte
     * at a time.
     */
    logic [31:0] sub_word_reg;

    /*
     * byte_index controls which byte of rot_word_reg is currently
     * being sent into the shared S-box.
     *
     * 0 -> rot_word_reg[31:24]
     * 1 -> rot_word_reg[23:16]
     * 2 -> rot_word_reg[15:8]
     * 3 -> rot_word_reg[7:0]
     */
    logic [1:0] byte_index;

    // Input to the single shared S-box.
    logic [7:0] sbox_in;

    // Output from the single shared S-box.
    logic [7:0] sbox_out;

    /*
     * Intermediate key schedule words.
     *
     * g_word:
     *   SubWord(RotWord(w3)) after Rcon is applied.
     *
     * w4, w5, w6, w7:
     *   The four words of the next AES round key.
     */
    logic [31:0] g_word;
    logic [31:0] w4;
    logic [31:0] w5;
    logic [31:0] w6;
    logic [31:0] w7;

    /*
     * Single shared S-box instance.
     *
     * In the optimized design, this sbox module should be replaced
     * by the fixed Boolean S-box implementation, not the baseline
     * lookup-table S-box.
     */
    sbox u_shared_sbox
    (
        .in_byte  (sbox_in),
        .out_byte (sbox_out)
    );

    /*
     * Select one byte of rot_word_reg for the shared S-box.
     *
     * The selected byte depends on byte_index.
     */
    always_comb begin
        case (byte_index)

            2'd0: begin
                sbox_in = rot_word_reg[31:24];
            end

            2'd1: begin
                sbox_in = rot_word_reg[23:16];
            end

            2'd2: begin
                sbox_in = rot_word_reg[15:8];
            end

            2'd3: begin
                sbox_in = rot_word_reg[7:0];
            end

            default: begin
                sbox_in = 8'h00;
            end

        endcase
    end

    /*
     * Apply Rcon to SubWord result.
     *
     * Rcon is XORed only into the most significant byte.
     *
     * Equivalent:
     *   g_word[31:24] = sub_word_reg[31:24] XOR rcon_reg
     *   g_word[23:0]  = sub_word_reg[23:0]
     */
    assign g_word = sub_word_reg ^ {rcon_reg, 24'h000000};

    /*
     * AES-128 XOR chaining for next round key generation.
     */
    assign w4 = w0_reg ^ g_word;
    assign w5 = w1_reg ^ w4;
    assign w6 = w2_reg ^ w5;
    assign w7 = w3_reg ^ w6;

    /*
     * Sequential FSM.
     *
     * The key expansion process is:
     *
     *   S_IDLE:
     *     Wait for start and latch key_in/rcon_byte.
     *
     *   S_SUBWORD:
     *     Use the shared S-box to substitute one byte per cycle.
     *
     *   S_CALC:
     *     Combine the substituted word with Rcon, generate key_out,
     *     pulse done, then return to S_IDLE.
     */
    always_ff @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin
            state        <= S_IDLE;

            w0_reg       <= 32'h0;
            w1_reg       <= 32'h0;
            w2_reg       <= 32'h0;
            w3_reg       <= 32'h0;

            rcon_reg     <= 8'h00;
            rot_word_reg <= 32'h0;
            sub_word_reg <= 32'h0;
            byte_index   <= 2'd0;

            key_out      <= 128'h0;
            done         <= 1'b0;
        end

        else begin
            // done is cleared by default so it behaves as a one-clock pulse.
            done <= 1'b0;

            case (state)

                S_IDLE: begin
                    if (start) begin
                        // Latch the current round key words.
                        w0_reg <= key_in[127:96];
                        w1_reg <= key_in[95:64];
                        w2_reg <= key_in[63:32];
                        w3_reg <= key_in[31:0];

                        // Latch the Rcon value for this round.
                        rcon_reg <= rcon_byte;

                        /*
                         * Prepare RotWord(w3).
                         *
                         * key_in[31:0] is w3.
                         * RotWord rotates w3 left by one byte:
                         *
                         *   w3 = {a0, a1, a2, a3}
                         *   RotWord(w3) = {a1, a2, a3, a0}
                         */
                        rot_word_reg <= {key_in[23:0], key_in[31:24]};

                        // Clear SubWord storage before filling it byte by byte.
                        sub_word_reg <= 32'h0;

                        // Start with the most significant byte.
                        byte_index <= 2'd0;

                        // Move to byte-by-byte SubWord processing.
                        state <= S_SUBWORD;
                    end
                end

                S_SUBWORD: begin
                    /*
                     * Store the current S-box output into the correct byte
                     * position of sub_word_reg.
                     *
                     * Because the S-box is combinational, sbox_out corresponds
                     * to the byte selected by byte_index in the same cycle.
                     */
                    case (byte_index)

                        2'd0: begin
                            sub_word_reg[31:24] <= sbox_out;
                            byte_index          <= 2'd1;
                        end

                        2'd1: begin
                            sub_word_reg[23:16] <= sbox_out;
                            byte_index          <= 2'd2;
                        end

                        2'd2: begin
                            sub_word_reg[15:8] <= sbox_out;
                            byte_index         <= 2'd3;
                        end

                        2'd3: begin
                            sub_word_reg[7:0] <= sbox_out;
                            byte_index        <= 2'd0;

                            // All four SubWord bytes are now collected.
                            state <= S_CALC;
                        end

                        default: begin
                            byte_index <= 2'd0;
                            state      <= S_IDLE;
                        end

                    endcase
                end

                S_CALC: begin
                    /*
                     * Generate and register the next round key.
                     *
                     * At this point, sub_word_reg contains:
                     *   SubWord(RotWord(w3))
                     *
                     * The continuous assignments above calculate:
                     *   g_word, w4, w5, w6, w7
                     */
                    key_out <= {w4, w5, w6, w7};

                    /*
                     * Pulse done in the same cycle key_out is registered.
                     *
                     * After this clock edge:
                     *   - key_out is valid.
                     *   - done is high for one clock cycle.
                     *
                     * This removes the separate S_DONE state and saves
                     * one clock cycle for every key expansion.
                     */
                    done <= 1'b1;

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