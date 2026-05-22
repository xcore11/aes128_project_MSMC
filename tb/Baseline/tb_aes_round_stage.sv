/**
 * @file tb_aes_round_stage.sv
 * @brief Stage-level testbench for baseline aes_round module.
 *
 * This testbench uses the FIPS 197 AES-128 example and checks:
 *   - Round 1 internal SubBytes, ShiftRows, MixColumns, AddRoundKey
 *   - Round outputs for Rounds 1 to 9
 *   - Final-round output for Round 10, where MixColumns is skipped
 */

`timescale 1ns/1ps

module tb_aes_round_stage;

    logic [127:0] state_in;
    logic [127:0] round_key;
    logic         final_round;
    logic [127:0] state_out;

    integer test_count;
    integer pass_count;
    integer fail_count;

    aes_round dut
    (
        .state_in    (state_in),
        .round_key   (round_key),
        .final_round (final_round),
        .state_out   (state_out)
    );

    task check_value;
        input string      label;
        input logic [127:0] got;
        input logic [127:0] expected;
    begin
        test_count = test_count + 1;

        if (got === expected)
        begin
            pass_count = pass_count + 1;
            $display("TEST %0d PASS: %s", test_count, label);
        end
        else
        begin
            fail_count = fail_count + 1;
            $display("TEST %0d FAIL: %s", test_count, label);
            $display("EXPECTED = %032h", expected);
            $display("GOT      = %032h", got);
        end
    end
    endtask

    task check_round_output;
        input logic [127:0] input_state;
        input logic [127:0] input_round_key;
        input logic         input_final_round;
        input logic [127:0] expected_state;
        input string        label;
    begin
        state_in    = input_state;
        round_key   = input_round_key;
        final_round = input_final_round;
        #1;

        check_value(label, state_out, expected_state);
    end
    endtask

    initial
    begin
        test_count  = 0;
        pass_count  = 0;
        fail_count  = 0;
        state_in    = 128'h0;
        round_key   = 128'h0;
        final_round = 1'b0;

        $display("==============================================");
        $display("AES Round Stage-Level Test Started");
        $display("==============================================");

        /* Round 1 internal stage checks. */
        state_in    = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        round_key   = 128'ha0fafe1788542cb123a339392a6c7605;
        final_round = 1'b0;
        #1;

        check_value("Round 1 SubBytes output",
                    dut.sub_bytes_out,
                    128'hd42711aee0bf98f1b8b45de51e415230);
        check_value("Round 1 ShiftRows output",
                    dut.shift_rows_out,
                    128'hd4bf5d30e0b452aeb84111f11e2798e5);
        check_value("Round 1 MixColumns output",
                    dut.mix_columns_out,
                    128'h046681e5e0cb199a48f8d37a2806264c);
        check_value("Round 1 AddRoundKey output",
                    state_out,
                    128'ha49c7ff2689f352b6b5bea43026a5049);

        /* Full one-round output checks for FIPS 197 Rounds 2 to 10. */
        check_round_output(128'ha49c7ff2689f352b6b5bea43026a5049,
                           128'hf2c295f27a96b9435935807a7359f67f,
                           1'b0,
                           128'haa8f5f0361dde3ef82d24ad26832469a,
                           "Round 2 full output");
        check_round_output(128'haa8f5f0361dde3ef82d24ad26832469a,
                           128'h3d80477d4716fe3e1e237e446d7a883b,
                           1'b0,
                           128'h486c4eee671d9d0d4de3b138d65f58e7,
                           "Round 3 full output");
        check_round_output(128'h486c4eee671d9d0d4de3b138d65f58e7,
                           128'hef44a541a8525b7fb671253bdb0bad00,
                           1'b0,
                           128'he0927fe8c86363c0d9b1355085b8be01,
                           "Round 4 full output");
        check_round_output(128'he0927fe8c86363c0d9b1355085b8be01,
                           128'hd4d1c6f87c839d87caf2b8bc11f915bc,
                           1'b0,
                           128'hf1006f55c1924cef7cc88b325db5d50c,
                           "Round 5 full output");
        check_round_output(128'hf1006f55c1924cef7cc88b325db5d50c,
                           128'h6d88a37a110b3efddbf98641ca0093fd,
                           1'b0,
                           128'h260e2e173d41b77de86472a9fdd28b25,
                           "Round 6 full output");
        check_round_output(128'h260e2e173d41b77de86472a9fdd28b25,
                           128'h4e54f70e5f5fc9f384a64fb24ea6dc4f,
                           1'b0,
                           128'h5a4142b11949dc1fa3e019657a8c040c,
                           "Round 7 full output");
        check_round_output(128'h5a4142b11949dc1fa3e019657a8c040c,
                           128'head27321b58dbad2312bf5607f8d292f,
                           1'b0,
                           128'hea835cf00445332d655d98ad8596b0c5,
                           "Round 8 full output");
        check_round_output(128'hea835cf00445332d655d98ad8596b0c5,
                           128'hac7766f319fadc2128d12941575c006e,
                           1'b0,
                           128'heb40f21e592e38848ba113e71bc342d2,
                           "Round 9 full output");
        check_round_output(128'heb40f21e592e38848ba113e71bc342d2,
                           128'hd014f9a8c9ee2589e13f0cc8b6630ca6,
                           1'b1,
                           128'h3925841d02dc09fbdc118597196a0b32,
                           "Round 10 final-round output");

        $display("==============================================");
        $display("AES Round Stage Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: AES ROUND STAGE TEST PASSED");
        end
        else
        begin
            $display("RESULT: AES ROUND STAGE TEST FAILED");
        end

        $stop;
    end

endmodule
