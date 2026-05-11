`timescale 1ns/1ps
`default_nettype none

/*
 * ============================================================
 * File        : aes_top_low_area.sv
 * Description : AES-128 low-area shared-resource top-level wrapper
 *
 * This wrapper keeps the same external start/busy/done interface as
 * the baseline design, but it instantiates aes_core_low_area instead
 * of aes_core_baseline.
 * ============================================================
 */

module aes_top_low_area
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

    aes_core_low_area u_aes_core_low_area
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
