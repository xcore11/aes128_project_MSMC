`timescale 1ns/1ps
`default_nettype none

/*
 * ============================================================
 * File        : aes_core_low_area.sv
 * Description : AES-128 encryption core, low-area shared-resource version
 *
 * Architecture:
 *   - AES-128 encryption only.
 *   - Multi-cycle shared-resource datapath.
 *   - Only ONE S-box instance is used for both:
 *       1) KeyExpansion SubWord
 *       2) AES state SubBytes
 *   - Only ONE mix_columns_one_column instance is used and reused
 *     across the four AES state columns.
 *   - ShiftRows is kept as combinational byte rewiring because it is
 *     very small compared with S-box and MixColumns hardware.
 *   - AddRoundKey is implemented directly as a 128-bit XOR.
 *
 * Interface:
 *   Same as aes_core_baseline:
 *       clk, reset_n, start, plaintext, key, ciphertext, busy, done
 *
 * Cycle estimate, excluding the idle cycle before start:
 *   - Initial AddRoundKey: 1 cycle
 *   - Rounds 1..9:
 *       Key RotWord:       1 cycle
 *       Key SubWord:       4 cycles
 *       Make RoundKey:     1 cycle
 *       SubBytes:         16 cycles
 *       ShiftRows:         1 cycle
 *       MixColumns:        4 cycles
 *       AddRoundKey:       1 cycle
 *       = 28 cycles each with this explicit FSM
 *   - Round 10 skips MixColumns:
 *       24 cycles
 *   - Final DONE pulse: 1 cycle
 *
 * Main optimization versus baseline:
 *   Baseline active hierarchy uses 16 S-boxes for SubBytes, 4 S-boxes
 *   for KeyExpansion, and 4 MixColumns column units. This version uses
 *   one shared S-box and one shared MixColumns column unit, increasing
 *   latency but reducing datapath area.
 * ============================================================
 */

module aes_core_low_area
(
    input  logic         clk,
    input  logic         reset_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    output logic [127:0] ciphertext,
    output logic         busy,
    output logic         done
);

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_INIT_ADDKEY,
        ST_KEY_ROTWORD,
        ST_KEY_SUBWORD,
        ST_KEY_MAKE_ROUNDKEY,
        ST_SUBBYTES,
        ST_SHIFTROWS,
        ST_MIXCOLUMNS,
        ST_ADDROUNDKEY,
        ST_DONE
    } state_t;

    state_t state;

    // AES state and current round key registers.
    logic [127:0] state_reg;
    logic [127:0] round_key_reg;

    // Temporary register used when building SubBytes or MixColumns results.
    logic [127:0] temp_state_reg;
    logic [127:0] temp_state_next;

    // AES round number: 1..10 while active.
    logic [3:0] round_reg;

    // Shared counters.
    logic [3:0] byte_count;  // 0..15 for SubBytes, 0..3 for Key SubWord
    logic [1:0] col_count;   // 0..3 for MixColumns columns

    // Rcon byte used while generating the next AES round key.
    logic [7:0] rcon_reg;

    // Key schedule temporary values.
    logic [31:0] rot_word_reg;
    logic [31:0] sub_word_reg;
    logic [31:0] sub_word_next;
    logic [31:0] g_word;
    logic [31:0] w0, w1, w2, w3;
    logic [31:0] w4, w5, w6, w7;
    logic [127:0] next_round_key;

    // One shared S-box.
    logic [7:0] sbox_in;
    logic [7:0] sbox_out;

    // One shared MixColumns column unit.
    logic [31:0] mix_col_in;
    logic [31:0] mix_col_out;

    // ShiftRows output.
    logic [127:0] shift_rows_out;

    /*
     * One and only one S-box instance in the low-area core.
     * The sbox_in mux selects either a key byte or a state byte.
     */
    sbox u_shared_sbox
    (
        .in_byte  (sbox_in),
        .out_byte (sbox_out)
    );

    /*
     * One and only one MixColumns column datapath in the low-area core.
     */
    mix_columns_one_column u_shared_mix_columns_one_column
    (
        .col_in  (mix_col_in),
        .col_out (mix_col_out)
    );

    /*
     * ShiftRows is only byte rewiring, so keeping this combinational block
     * does not duplicate expensive datapath hardware.
     */
    shift_rows u_shift_rows
    (
        .state_in  (state_reg),
        .state_out (shift_rows_out)
    );

    // Split current round key into words for AES-128 key schedule.
    assign w0 = round_key_reg[127:96];
    assign w1 = round_key_reg[95:64];
    assign w2 = round_key_reg[63:32];
    assign w3 = round_key_reg[31:0];

    assign g_word = sub_word_reg ^ {rcon_reg, 24'h000000};
    assign w4 = w0 ^ g_word;
    assign w5 = w1 ^ w4;
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;
    assign next_round_key = {w4, w5, w6, w7};

    /*
     * Shared S-box input mux.
     *
     * ST_KEY_SUBWORD uses byte_count 0..3 to substitute RotWord bytes.
     * ST_SUBBYTES uses byte_count 0..15 to substitute AES state bytes.
     */
    always_comb begin
        sbox_in = 8'h00;

        unique case (state)
            ST_KEY_SUBWORD: begin
                unique case (byte_count[1:0])
                    2'd0: sbox_in = rot_word_reg[31:24];
                    2'd1: sbox_in = rot_word_reg[23:16];
                    2'd2: sbox_in = rot_word_reg[15:8];
                    2'd3: sbox_in = rot_word_reg[7:0];
                    default: sbox_in = 8'h00;
                endcase
            end

            ST_SUBBYTES: begin
                sbox_in = state_reg[8*byte_count +: 8];
            end

            default: begin
                sbox_in = 8'h00;
            end
        endcase
    end

    /*
     * Build next SubWord value one S-box byte at a time.
     */
    always_comb begin
        sub_word_next = sub_word_reg;

        unique case (byte_count[1:0])
            2'd0: sub_word_next[31:24] = sbox_out;
            2'd1: sub_word_next[23:16] = sbox_out;
            2'd2: sub_word_next[15:8]  = sbox_out;
            2'd3: sub_word_next[7:0]   = sbox_out;
            default: sub_word_next = sub_word_reg;
        endcase
    end

    /*
     * Build next 128-bit temporary state for SubBytes or MixColumns.
     * Using *_next avoids losing the last byte/column on the final cycle
     * of a multi-cycle operation.
     */
    always_comb begin
        temp_state_next = temp_state_reg;

        unique case (state)
            ST_SUBBYTES: begin
                temp_state_next[8*byte_count +: 8] = sbox_out;
            end

            ST_MIXCOLUMNS: begin
                unique case (col_count)
                    2'd0: temp_state_next[127:96] = mix_col_out;
                    2'd1: temp_state_next[95:64]  = mix_col_out;
                    2'd2: temp_state_next[63:32]  = mix_col_out;
                    2'd3: temp_state_next[31:0]   = mix_col_out;
                    default: temp_state_next = temp_state_reg;
                endcase
            end

            default: begin
                temp_state_next = temp_state_reg;
            end
        endcase
    end

    /*
     * Select one AES column for the single shared MixColumns column block.
     */
    always_comb begin
        unique case (col_count)
            2'd0: mix_col_in = state_reg[127:96];
            2'd1: mix_col_in = state_reg[95:64];
            2'd2: mix_col_in = state_reg[63:32];
            2'd3: mix_col_in = state_reg[31:0];
            default: mix_col_in = 32'h00000000;
        endcase
    end

    /*
     * Main FSM and datapath register updates.
     */
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state          <= ST_IDLE;
            state_reg      <= 128'h0;
            round_key_reg  <= 128'h0;
            temp_state_reg <= 128'h0;
            ciphertext     <= 128'h0;
            round_reg      <= 4'd0;
            byte_count     <= 4'd0;
            col_count      <= 2'd0;
            rcon_reg       <= 8'h00;
            rot_word_reg   <= 32'h0;
            sub_word_reg   <= 32'h0;
            busy           <= 1'b0;
            done           <= 1'b0;
        end
        else begin
            // done is a one-cycle pulse.
            done <= 1'b0;

            unique case (state)
                ST_IDLE: begin
                    busy           <= 1'b0;
                    round_reg      <= 4'd0;
                    byte_count     <= 4'd0;
                    col_count      <= 2'd0;
                    rcon_reg       <= 8'h00;
                    temp_state_reg <= 128'h0;
                    rot_word_reg   <= 32'h0;
                    sub_word_reg   <= 32'h0;

                    if (start) begin
                        busy          <= 1'b1;
                        state_reg     <= plaintext;
                        round_key_reg <= key;
                        state         <= ST_INIT_ADDKEY;
                    end
                end

                ST_INIT_ADDKEY: begin
                    // Initial AES AddRoundKey: state = plaintext XOR K0.
                    state_reg      <= state_reg ^ round_key_reg;
                    round_reg      <= 4'd1;
                    rcon_reg       <= 8'h01;
                    byte_count     <= 4'd0;
                    col_count      <= 2'd0;
                    temp_state_reg <= 128'h0;
                    state          <= ST_KEY_ROTWORD;
                end

                ST_KEY_ROTWORD: begin
                    // RotWord(w3): {a0,a1,a2,a3} -> {a1,a2,a3,a0}.
                    rot_word_reg <= {round_key_reg[23:0], round_key_reg[31:24]};
                    sub_word_reg <= 32'h0;
                    byte_count   <= 4'd0;
                    state        <= ST_KEY_SUBWORD;
                end

                ST_KEY_SUBWORD: begin
                    // Reuse the one S-box for four cycles to build SubWord.
                    sub_word_reg <= sub_word_next;

                    if (byte_count == 4'd3) begin
                        byte_count <= 4'd0;
                        state      <= ST_KEY_MAKE_ROUNDKEY;
                    end
                    else begin
                        byte_count <= byte_count + 4'd1;
                    end
                end

                ST_KEY_MAKE_ROUNDKEY: begin
                    // Generate and store Kround from the previous round key.
                    round_key_reg  <= next_round_key;
                    temp_state_reg <= 128'h0;
                    byte_count     <= 4'd0;
                    state          <= ST_SUBBYTES;
                end

                ST_SUBBYTES: begin
                    // Reuse the one S-box for sixteen cycles, one state byte per cycle.
                    temp_state_reg <= temp_state_next;

                    if (byte_count == 4'd15) begin
                        state_reg  <= temp_state_next;
                        byte_count <= 4'd0;
                        state      <= ST_SHIFTROWS;
                    end
                    else begin
                        byte_count <= byte_count + 4'd1;
                    end
                end

                ST_SHIFTROWS: begin
                    state_reg      <= shift_rows_out;
                    temp_state_reg <= 128'h0;
                    col_count      <= 2'd0;

                    if (round_reg == 4'd10) begin
                        // AES final round skips MixColumns.
                        state <= ST_ADDROUNDKEY;
                    end
                    else begin
                        state <= ST_MIXCOLUMNS;
                    end
                end

                ST_MIXCOLUMNS: begin
                    // Reuse one MixColumns column block for four cycles.
                    temp_state_reg <= temp_state_next;

                    if (col_count == 2'd3) begin
                        state_reg <= temp_state_next;
                        col_count <= 2'd0;
                        state     <= ST_ADDROUNDKEY;
                    end
                    else begin
                        col_count <= col_count + 2'd1;
                    end
                end

                ST_ADDROUNDKEY: begin
                    // AddRoundKey for this round using the round key just generated.
                    state_reg <= state_reg ^ round_key_reg;

                    if (round_reg == 4'd10) begin
                        ciphertext <= state_reg ^ round_key_reg;
                        state      <= ST_DONE;
                    end
                    else begin
                        round_reg <= round_reg + 4'd1;
                        rcon_reg  <= aes_xtime(rcon_reg);
                        state     <= ST_KEY_ROTWORD;
                    end
                end

                ST_DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

    /*
     * AES xtime function: multiply by 02 in GF(2^8).
     * Used only for Rcon update in this low-area core.
     */
    function automatic logic [7:0] aes_xtime
    (
        input logic [7:0] b
    );
        begin
            if (b[7] == 1'b1) begin
                aes_xtime = (b << 1) ^ 8'h1b;
            end
            else begin
                aes_xtime = (b << 1);
            end
        end
    endfunction

endmodule

`default_nettype wire
