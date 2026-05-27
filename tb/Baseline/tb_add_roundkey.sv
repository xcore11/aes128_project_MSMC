/**
 * @file tb_add_roundkey.sv
 * @brief Unit testbench for the AES AddRoundKey block.
 *
 * This testbench verifies:
 *
 *     state_out = state_in XOR round_key
 *
 * It includes edge cases, deterministic patterns, and FIPS 197
 * AES-128 round-key examples.
 */

`timescale 1ns / 1ps

module tb_add_roundkey;

    logic [127:0] state_in;
    logic [127:0] round_key;
    logic [127:0] state_out;

    integer test_count;
    integer pass_count;
    integer fail_count;

    add_roundkey dut
    (
        .state_in  (state_in),
        .round_key (round_key),
        .state_out (state_out)
    );

    task run_test;
        input logic [127:0] input_state;
        input logic [127:0] input_round_key;
        input logic [127:0] expected_state;
        input string        test_name;
    begin
        state_in  = input_state;
        round_key = input_round_key;
        #1;

        test_count = test_count + 1;

        $display("----------------------------------------------");
        $display("TEST %0d: %s", test_count, test_name);
        $display("Operation : AddRoundKey");
        $display("STATE_IN  = %032h", input_state);
        $display("ROUND_KEY = %032h", input_round_key);
        $display("EXPECTED  = %032h", expected_state);
        $display("GOT       = %032h", state_out);

        if (state_out === expected_state)
        begin
            pass_count = pass_count + 1;
            $display("STATUS    = PASS");
        end
        else
        begin
            fail_count = fail_count + 1;
            $display("STATUS    = FAIL");
        end
    end
    endtask

    task run_auto_test;
        input logic [127:0] input_state;
        input logic [127:0] input_round_key;
        input string        test_name;
    begin
        run_test(input_state, input_round_key, input_state ^ input_round_key, test_name);
    end
    endtask

    initial
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        $display("==============================================");
        $display("AES AddRoundKey Unit Test Started");
        $display("==============================================");

        run_auto_test(128'h00000000000000000000000000000000,
                      128'h00000000000000000000000000000000,
                      "zero_state_zero_key");
        run_auto_test(128'h00000000000000000000000000000000,
                      128'h2b7e151628aed2a6abf7158809cf4f3c,
                      "zero_state_xor_fips_key");
        run_auto_test(128'hffffffffffffffffffffffffffffffff,
                      128'h0123456789abcdeffedcba9876543210,
                      "all_ones_state_xor_pattern_key");
        run_auto_test(128'h0123456789abcdeffedcba9876543210,
                      128'hfedcba98765432100123456789abcdef,
                      "complementary_patterns");
        run_auto_test(128'h6bc1bee22e409f96e93d7e117393172a,
                      128'h2b7e151628aed2a6abf7158809cf4f3c,
                      "nist_block1_xor_fips_key");
        run_auto_test(128'hae2d8a571e03ac9c9eb76fac45af8e51,
                      128'ha0fafe1788542cb123a339392a6c7605,
                      "nist_block2_xor_round1_key");
        run_auto_test(128'h30c81c46a35ce411e5fbc1191a0a52ef,
                      128'hf2c295f27a96b9435935807a7359f67f,
                      "nist_block3_xor_round2_key");

        /* FIPS 197 Appendix B initial AddRoundKey. */
        run_test(128'h3243f6a8885a308d313198a2e0370734,
                 128'h2b7e151628aed2a6abf7158809cf4f3c,
                 128'h193de3bea0f4e22b9ac68d2ae9f84808,
                 "fips197_initial_addroundkey");

        /* FIPS 197 Appendix B round AddRoundKey results. */
        run_test(128'h046681e5e0cb199a48f8d37a2806264c,
                 128'ha0fafe1788542cb123a339392a6c7605,
                 128'ha49c7ff2689f352b6b5bea43026a5049,
                 "fips197_round1_addroundkey");
        run_test(128'h584dcaf11b4b5aacdbe7caa81b6bb0e5,
                 128'hf2c295f27a96b9435935807a7359f67f,
                 128'haa8f5f0361dde3ef82d24ad26832469a,
                 "fips197_round2_addroundkey");
        run_test(128'h75ec0993200b633353c0cf7cbb25d0dc,
                 128'h3d80477d4716fe3e1e237e446d7a883b,
                 128'h486c4eee671d9d0d4de3b138d65f58e7,
                 "fips197_round3_addroundkey");
        run_test(128'he9317db5cb322c723d2e895faf090794,
                 128'hd014f9a8c9ee2589e13f0cc8b6630ca6,
                 128'h3925841d02dc09fbdc118597196a0b32,
                 "fips197_final_addroundkey");

        $display("==============================================");
        $display("AES AddRoundKey Unit Test Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: ALL ADDROUNDKEY TESTS PASSED");
        end
        else
        begin
            $display("RESULT: ADDROUNDKEY TEST FAILED");
        end

        $stop;
    end

endmodule
