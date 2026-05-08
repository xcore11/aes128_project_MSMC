`timescale 1ns/1ps
`default_nettype none

// ============================================================
// File        : aes128_all.sv
// Description : AES-128 encryption core, single-file RTL version
//
// Current architecture:
//   - AES-128 encryption only
//   - Iterative one-round-per-cycle datapath
//   - Start / busy / done wrapper interface
//   - S-box kept as a separate module for later implementation choice
//
// Important:
//   The current sbox module is only a placeholder.
//   Replace it with the real AES S-box before functional simulation.
// ============================================================


// ============================================================
// 1. S-box block
//
// This module is intentionally kept separate because the final
// S-box implementation option has not been selected yet.
//
// Later, this module can be replaced by:
//   1. case-statement S-box
//   2. lookup-table S-box
//   3. ROM-style S-box
//   4. Boolean-logic S-box
//
// Current placeholder:
//   out_byte = in_byte
//
// This pass-through version is better than assigning 8'h00,
// because assigning constant zero may cause Quartus to optimize
// away large parts of the AES datapath during early compilation.
// ============================================================
module sbox (
    input  logic [7:0] in_byte,
    output logic [7:0] out_byte
);

    always_comb begin
        // TODO:
        // Replace this with the real AES S-box.
        out_byte = in_byte;
    end

endmodule


// ============================================================
// 2. AddRoundKey
//
// AES AddRoundKey operation:
//   state_out = state_in XOR round_key
//
// This is the simplest AES operation. It is purely combinational
// and synthesizes into 128 XOR gates.
// ============================================================
module addroundkey (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    output logic [127:0] state_out
);

    assign state_out = state_in ^ round_key;

endmodule


// ============================================================
// 3. SubBytes
//
// Applies the AES S-box independently to all 16 bytes of the
// 128-bit state.
//
// Hardware structure:
//   - 16 parallel S-box instances
//
// Reason:
//   This gives one-round-per-cycle operation because all bytes
//   are substituted in the same clock cycle.
// ============================================================
module subbytes (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_sbox
            sbox u_sbox (
                .in_byte  (state_in [8*i +: 8]),
                .out_byte (state_out[8*i +: 8])
            );
        end
    endgenerate

endmodule


// ============================================================
// 4. ShiftRows
//
// AES state byte ordering used in this design:
//
//   state = {b0, b1, b2, b3,
//            b4, b5, b6, b7,
//            b8, b9, b10, b11,
//            b12, b13, b14, b15}
//
// AES matrix form:
//
//   [ b0   b4   b8   b12 ]
//   [ b1   b5   b9   b13 ]
//   [ b2   b6   b10  b14 ]
//   [ b3   b7   b11  b15 ]
//
// ShiftRows result:
//
//   Row 0: no shift
//   Row 1: shift left by 1 byte
//   Row 2: shift left by 2 bytes
//   Row 3: shift left by 3 bytes
//
// This block is only fixed byte reordering.
// It does not require logic gates or arithmetic.
// ============================================================
module shiftrows (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    assign state_out = {
        state_in[127:120], state_in[87:80],   state_in[47:40],   state_in[7:0],
        state_in[95:88],   state_in[55:48],   state_in[15:8],     state_in[103:96],
        state_in[63:56],   state_in[23:16],   state_in[111:104],  state_in[71:64],
        state_in[31:24],   state_in[119:112], state_in[79:72],    state_in[39:32]
    };

endmodule


// ============================================================
// 5. MixColumns one column
//
// Performs AES MixColumns operation on one 32-bit column.
//
// Input column:
//   col_in = {s0, s1, s2, s3}
//
// AES MixColumns equations:
//
//   m0 = 02*s0 XOR 03*s1 XOR 01*s2 XOR 01*s3
//   m1 = 01*s0 XOR 02*s1 XOR 03*s2 XOR 01*s3
//   m2 = 01*s0 XOR 01*s1 XOR 02*s2 XOR 03*s3
//   m3 = 03*s0 XOR 01*s1 XOR 01*s2 XOR 02*s3
//
// In AES GF(2^8):
//   02*x = xtime(x)
//   03*x = xtime(x) XOR x
//
// Optimization used:
//   xtime(s0), xtime(s1), xtime(s2), xtime(s3)
//   are calculated once and reused.
// ============================================================
module mixcolumns_one_column (
    input  logic [31:0] col_in,
    output logic [31:0] col_out
);

    logic [7:0] s0, s1, s2, s3;
    logic [7:0] x0, x1, x2, x3;
    logic [7:0] m0, m1, m2, m3;

    assign s0 = col_in[31:24];
    assign s1 = col_in[23:16];
    assign s2 = col_in[15:8];
    assign s3 = col_in[7:0];

    // Precompute multiplication by 02.
    assign x0 = aes_xtime(s0);
    assign x1 = aes_xtime(s1);
    assign x2 = aes_xtime(s2);
    assign x3 = aes_xtime(s3);

    // MixColumns equations.
    assign m0 = x0 ^ (x1 ^ s1) ^ s2 ^ s3;
    assign m1 = s0 ^ x1 ^ (x2 ^ s2) ^ s3;
    assign m2 = s0 ^ s1 ^ x2 ^ (x3 ^ s3);
    assign m3 = (x0 ^ s0) ^ s1 ^ s2 ^ x3;

    assign col_out = {m0, m1, m2, m3};

    // --------------------------------------------------------
    // aes_xtime
    //
    // Performs multiplication by 02 in AES GF(2^8).
    //
    // If the input MSB is 1, reduction by AES polynomial
    // x^8 + x^4 + x^3 + x + 1 is required, represented by 8'h1b.
    // --------------------------------------------------------
    function automatic logic [7:0] aes_xtime(input logic [7:0] b);
        begin
            if (b[7] == 1'b1)
                aes_xtime = (b << 1) ^ 8'h1b;
            else
                aes_xtime = (b << 1);
        end
    endfunction

endmodule


// ============================================================
// 6. Full MixColumns
//
// AES state is stored column by column:
//
//   state[127:96] = column 0
//   state[95:64]  = column 1
//   state[63:32]  = column 2
//   state[31:0]   = column 3
//
// This block applies MixColumns to all four columns in parallel.
// ============================================================
module mixcolumns (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    mixcolumns_one_column u_col0 (
        .col_in  (state_in[127:96]),
        .col_out (state_out[127:96])
    );

    mixcolumns_one_column u_col1 (
        .col_in  (state_in[95:64]),
        .col_out (state_out[95:64])
    );

    mixcolumns_one_column u_col2 (
        .col_in  (state_in[63:32]),
        .col_out (state_out[63:32])
    );

    mixcolumns_one_column u_col3 (
        .col_in  (state_in[31:0]),
        .col_out (state_out[31:0])
    );

endmodule


// ============================================================
// 7. Key Expansion for One AES Round
//
// Input:
//   key_in     = current 128-bit round key
//   rcon_byte  = current AES round constant byte
//
// Output:
//   key_out    = next 128-bit round key
//
// AES-128 key schedule:
//
//   Current key:
//     key_in = {w0, w1, w2, w3}
//
//   Next key:
//     w4 = w0 XOR SubWord(RotWord(w3)) XOR Rcon
//     w5 = w1 XOR w4
//     w6 = w2 XOR w5
//     w7 = w3 XOR w6
//
//   key_out = {w4, w5, w6, w7}
//
// Optimization:
//   This module does not calculate Rcon using a case statement.
//   Instead, the AES core provides rcon_byte from a small register.
// ============================================================
module keyexpansion (
    input  logic [127:0] key_in,
    input  logic [7:0]   rcon_byte,
    output logic [127:0] key_out
);

    logic [31:0] w0, w1, w2, w3;
    logic [31:0] w4, w5, w6, w7;

    logic [31:0] rot_word;
    logic [31:0] sub_word;
    logic [31:0] g_word;

    assign w0 = key_in[127:96];
    assign w1 = key_in[95:64];
    assign w2 = key_in[63:32];
    assign w3 = key_in[31:0];

    // RotWord:
    //   [a0 a1 a2 a3] becomes [a1 a2 a3 a0]
    assign rot_word = {w3[23:0], w3[31:24]};

    // SubWord:
    // Apply S-box to each byte of rot_word.
    sbox u_key_sbox0 (
        .in_byte  (rot_word[31:24]),
        .out_byte (sub_word[31:24])
    );

    sbox u_key_sbox1 (
        .in_byte  (rot_word[23:16]),
        .out_byte (sub_word[23:16])
    );

    sbox u_key_sbox2 (
        .in_byte  (rot_word[15:8]),
        .out_byte (sub_word[15:8])
    );

    sbox u_key_sbox3 (
        .in_byte  (rot_word[7:0]),
        .out_byte (sub_word[7:0])
    );

    // Add Rcon to the most significant byte only.
    assign g_word = sub_word ^ {rcon_byte, 24'h000000};

    // Generate next four key words.
    assign w4 = w0 ^ g_word;
    assign w5 = w1 ^ w4;
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;

    assign key_out = {w4, w5, w6, w7};

endmodule


// ============================================================
// 8. AES Round
//
// Normal AES round:
//   SubBytes -> ShiftRows -> MixColumns -> AddRoundKey
//
// Final AES round:
//   SubBytes -> ShiftRows -> AddRoundKey
//
// final_round:
//   0 = normal round, includes MixColumns
//   1 = final round, skips MixColumns
// ============================================================
module aes_round (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    input  logic         final_round,
    output logic [127:0] state_out
);

    logic [127:0] subbytes_out;
    logic [127:0] shiftrows_out;
    logic [127:0] mixcolumns_out;
    logic [127:0] addroundkey_in;

    subbytes u_subbytes (
        .state_in  (state_in),
        .state_out (subbytes_out)
    );

    shiftrows u_shiftrows (
        .state_in  (subbytes_out),
        .state_out (shiftrows_out)
    );

    mixcolumns u_mixcolumns (
        .state_in  (shiftrows_out),
        .state_out (mixcolumns_out)
    );

    // Final round skips MixColumns.
    assign addroundkey_in = final_round ? shiftrows_out : mixcolumns_out;

    addroundkey u_addroundkey (
        .state_in  (addroundkey_in),
        .round_key (round_key),
        .state_out (state_out)
    );

endmodule


// ============================================================
// 9. AES-128 Core
//
// Architecture:
//   Iterative one-round-per-cycle AES-128 encryption core.
//
// Interface:
//   start      : pulse high for one clock cycle to begin encryption
//   busy       : high while encryption is running
//   done       : high for one clock cycle when ciphertext is valid
//   plaintext  : 128-bit input data
//   key        : 128-bit AES key
//   ciphertext : 128-bit encrypted output
//
// Cycle sequence:
//
//   Start cycle:
//     state_reg     <= plaintext XOR key
//     round_key_reg <= key
//     round_reg     <= 1
//     rcon_reg      <= 01
//
//   Round 1 to 9:
//     next_round_key = KeyExpansion(round_key_reg, rcon_reg)
//     state_reg      <= normal AES round using next_round_key
//     round_key_reg  <= next_round_key
//     rcon_reg       <= xtime(rcon_reg)
//
//   Round 10:
//     next_round_key = KeyExpansion(round_key_reg, rcon_reg)
//     ciphertext     <= final AES round using next_round_key
//     done           <= 1
//
// Latency:
//   10 round cycles after start is accepted.
// ============================================================
module aes_core (
    input  logic         clk,
    input  logic         reset_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,

    output logic [127:0] ciphertext,
    output logic         busy,
    output logic         done
);

    logic [127:0] state_reg;
    logic [127:0] round_key_reg;
    logic [3:0]   round_reg;
    logic [7:0]   rcon_reg;

    logic [127:0] next_round_key;
    logic [127:0] round_state_out;
    logic         final_round;

    assign final_round = (round_reg == 4'd10);

    keyexpansion u_keyexpansion (
        .key_in     (round_key_reg),
        .rcon_byte  (rcon_reg),
        .key_out    (next_round_key)
    );

    aes_round u_aes_round (
        .state_in    (state_reg),
        .round_key   (next_round_key),
        .final_round (final_round),
        .state_out   (round_state_out)
    );

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_reg     <= 128'h0;
            round_key_reg <= 128'h0;
            round_reg     <= 4'd0;
            rcon_reg      <= 8'h00;
            ciphertext    <= 128'h0;
            busy          <= 1'b0;
            done          <= 1'b0;
        end
        else begin
            // done is a one-clock pulse.
            done <= 1'b0;

            // Accept a new encryption request only when core is idle.
            if (start && !busy) begin
                state_reg     <= plaintext ^ key;
                round_key_reg <= key;
                round_reg     <= 4'd1;
                rcon_reg      <= 8'h01;
                busy          <= 1'b1;
            end

            // Run AES rounds while busy.
            else if (busy) begin
                state_reg     <= round_state_out;
                round_key_reg <= next_round_key;

                if (round_reg == 4'd10) begin
                    ciphertext <= round_state_out;
                    round_reg  <= 4'd0;
                    rcon_reg   <= 8'h00;
                    busy       <= 1'b0;
                    done       <= 1'b1;
                end
                else begin
                    round_reg <= round_reg + 4'd1;
                    rcon_reg  <= aes_xtime(rcon_reg);
                end
            end
        end
    end

    // --------------------------------------------------------
    // aes_xtime
    //
    // Used here to update the Rcon register:
    //   01 -> 02 -> 04 -> 08 -> 10 -> 20 -> 40 -> 80 -> 1b -> 36
    // --------------------------------------------------------
    function automatic logic [7:0] aes_xtime(input logic [7:0] b);
        begin
            if (b[7] == 1'b1)
                aes_xtime = (b << 1) ^ 8'h1b;
            else
                aes_xtime = (b << 1);
        end
    endfunction

endmodule


// ============================================================
// 10. Top-Level Wrapper
//
// Simple start/busy/done top-level interface.
//
// This is the easiest wrapper to verify first.
// Later, this wrapper can be replaced or extended with:
//   1. memory-mapped register interface
//   2. streaming input/output handshake
//   3. serial loading wrapper
//   4. debug/status register block
// ============================================================
module aes_top (
    input  logic         clk,
    input  logic         reset_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,

    output logic [127:0] ciphertext,
    output logic         busy,
    output logic         done
);

    aes_core u_aes_core (
        .clk        (clk),
        .reset_n    (reset_n),
        .start      (start),
        .plaintext  (plaintext),
        .key        (key),
        .ciphertext (ciphertext),
        .busy       (busy),
        .done       (done)
    );

endmodule

`default_nettype wire