`timescale 1ns/1ps
`default_nettype none

/*
 * ============================================================
 * File        : aes_top_optimized.sv
 * Description : AES-128 optimized top-level wrapper
 *
 * Project     : ECE4063 IC Design Project
 *
 * Architecture:
 *   - Low-area shared-resource AES-128 encryption design.
 *   - Boolean/GF logic S-box.
 *   - Sequential shared SubBytes.
 *   - Sequential shared key expansion.
 *   - One shared MixColumns column block.
 *   - Start / busy / done wrapper interface.
 *
 * Function:
 *   This module is the external entry point of the optimized AES
 *   design. It instantiates aes_core_optimized and exposes the
 *   same top-level interface as the baseline design.
 *
 * Notes:
 *   - Keeping the same top-level interface makes comparison with
 *     the baseline design easier.
 *   - The same testbench structure can be reused for both designs.
 * ============================================================
 */

module aes_top_optimized
(
    // System clock.
    input  logic         clk,

    // Active-low reset.
    input  logic         reset_n,

    // Pulse high for one clock cycle to start encryption.
    input  logic         start,

    // 128-bit plaintext input block.
    input  logic [127:0] plaintext,

    // 128-bit AES key.
    input  logic [127:0] key,

    // 128-bit ciphertext output block.
    output logic [127:0] ciphertext,

    // High while encryption is in progress.
    output logic         busy,

    // One-clock pulse when ciphertext is valid.
    output logic         done
);

    /*
     * Optimized AES core instance.
     */
    aes_core_optimized u_aes_core_optimized
    (
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