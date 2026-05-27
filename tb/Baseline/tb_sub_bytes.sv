/**
 * @file tb_sub_bytes.sv
 * @brief Unit testbench for the AES SubBytes block.
 *
 * The separate tb_sbox.sv testbench exhaustively verifies all 256
 * S-box input values. This testbench verifies the 128-bit SubBytes
 * wrapper and catches byte-ordering or missing-instance issues.
 */

`timescale 1ns / 1ps

module tb_sub_bytes;

    logic [127:0] state_in;
    logic [127:0] state_out;

    integer test_count;
    integer pass_count;
    integer fail_count;

    sub_bytes dut
    (
        .state_in  (state_in),
        .state_out (state_out)
    );

    task run_test;
        input logic [127:0] input_state;
        input logic [127:0] expected_state;
        input string        test_name;
    begin
        state_in = input_state;
        #1;

        test_count = test_count + 1;

        $display("----------------------------------------------");
        $display("TEST %0d: %s", test_count, test_name);
        $display("Operation = SubBytes");
        $display("STATE_IN  = %032h", input_state);
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

    initial
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        $display("==============================================");
        $display("AES SubBytes Unit Test Started");
        $display("==============================================");

        run_test(128'h00000000000000000000000000000000,
                 128'h63636363636363636363636363636363,
                 "all_zero_bytes");
        run_test(128'hffffffffffffffffffffffffffffffff,
                 128'h16161616161616161616161616161616,
                 "all_ff_bytes");
        run_test(128'h000102030405060708090a0b0c0d0e0f,
                 128'h637c777bf26b6fc53001672bfed7ab76,
                 "ascending_00_to_0f");
        run_test(128'h0f0e0d0c0b0a09080706050403020100,
                 128'h76abd7fe2b670130c56f6bf27b777c63,
                 "descending_0f_to_00");
        run_test(128'h0123456789abcdeffedcba9876543210,
					  128'h7c266e85a762bddfbb86f446382023ca,
					  "mixed_pattern_1");

		  run_test(128'h6bc1bee22e409f96e93d7e117393172a,
					  128'h7f78ae983109db901e27f3828fdcf0e5,
					  "nist_plaintext_block_1");
					  

        /* FIPS 197 Appendix B SubBytes results for Rounds 1 to 10. */
        run_test(128'h193de3bea0f4e22b9ac68d2ae9f84808,
                 128'hd42711aee0bf98f1b8b45de51e415230,
                 "fips197_round1_start_to_subbytes");
        run_test(128'ha49c7ff2689f352b6b5bea43026a5049,
                 128'h49ded28945db96f17f39871a7702533b,
                 "fips197_round2_start_to_subbytes");
        run_test(128'haa8f5f0361dde3ef82d24ad26832469a,
                 128'hac73cf7befc111df13b5d6b545235ab8,
                 "fips197_round3_start_to_subbytes");
        run_test(128'h486c4eee671d9d0d4de3b138d65f58e7,
                 128'h52502f2885a45ed7e311c807f6cf6a94,
                 "fips197_round4_start_to_subbytes");
        run_test(128'he0927fe8c86363c0d9b1355085b8be01,
                 128'he14fd29be8fbfbba35c89653976cae7c,
                 "fips197_round5_start_to_subbytes");
        run_test(128'hf1006f55c1924cef7cc88b325db5d50c,
                 128'ha163a8fc784f29df10e83d234cd503fe,
                 "fips197_round6_start_to_subbytes");
        run_test(128'h260e2e173d41b77de86472a9fdd28b25,
                 128'hf7ab31f02783a9ff9b4340d354b53d3f,
                 "fips197_round7_start_to_subbytes");
        run_test(128'h5a4142b11949dc1fa3e019657a8c040c,
                 128'hbe832cc8d43b86c00ae1d44dda64f2fe,
                 "fips197_round8_start_to_subbytes");
        run_test(128'hea835cf00445332d655d98ad8596b0c5,
                 128'h87ec4a8cf26ec3d84d4c46959790e7a6,
                 "fips197_round9_start_to_subbytes");
        run_test(128'heb40f21e592e38848ba113e71bc342d2,
                 128'he9098972cb31075f3d327d94af2e2cb5,
                 "fips197_round10_start_to_subbytes");

        $display("==============================================");
        $display("AES SubBytes Unit Test Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: ALL SUBBYTES TESTS PASSED");
        end
        else
        begin
            $display("RESULT: SUBBYTES TEST FAILED");
        end

        $stop;
    end

endmodule
