/**
 * @file tb_mix_columns.sv
 * @brief Unit testbench for the full 128-bit AES MixColumns module.
 *
 * This testbench verifies the complete MixColumns transformation:
 *
 *     state_in[127:0] -> state_out[127:0]
 *
 * It is stronger than testing only one column because it also checks
 * full-state column ordering and wiring.
 */

`timescale 1ns/1ps

module tb_mix_columns;

    logic [127:0] state_in;
    logic [127:0] state_out;

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer i;

    mix_columns dut
    (
        .state_in  (state_in),
        .state_out (state_out)
    );

    function automatic logic [7:0] xtime;
        input logic [7:0] value;
    begin
        if (value[7] == 1'b1)
        begin
            xtime = (value << 1) ^ 8'h1b;
        end
        else
        begin
            xtime = (value << 1);
        end
    end
    endfunction

    function automatic logic [31:0] ref_mix_column;
        input logic [31:0] col;
        logic [7:0] s0;
        logic [7:0] s1;
        logic [7:0] s2;
        logic [7:0] s3;
        logic [7:0] m0;
        logic [7:0] m1;
        logic [7:0] m2;
        logic [7:0] m3;
    begin
        s0 = col[31:24];
        s1 = col[23:16];
        s2 = col[15:8];
        s3 = col[7:0];

        m0 = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3;
        m1 = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
        m2 = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
        m3 = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);

        ref_mix_column = {m0, m1, m2, m3};
    end
    endfunction

    function automatic logic [127:0] ref_mix_columns;
        input logic [127:0] state;
    begin
        ref_mix_columns = {
            ref_mix_column(state[127:96]),
            ref_mix_column(state[95:64]),
            ref_mix_column(state[63:32]),
            ref_mix_column(state[31:0])
        };
    end
    endfunction

    task check_state;
        input logic [127:0] input_state;
        input logic [127:0] expected_state;
        input string        test_name;
    begin
        state_in = input_state;
        #1;

        test_count = test_count + 1;

        if (state_out === expected_state)
        begin
            pass_count = pass_count + 1;
            $display("TEST %0d PASS: %s", test_count, test_name);
        end
        else
        begin
            fail_count = fail_count + 1;
            $display("TEST %0d FAIL: %s", test_count, test_name);
            $display("INPUT    = %032h", input_state);
            $display("EXPECTED = %032h", expected_state);
            $display("GOT      = %032h", state_out);
        end
    end
    endtask

    task check_state_auto;
        input logic [127:0] input_state;
        input string        test_name;
    begin
        check_state(input_state, ref_mix_columns(input_state), test_name);
    end
    endtask

    initial
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        state_in   = 128'h0;

        $display("==============================================");
        $display("Full MixColumns Unit Test Started");
        $display("==============================================");

        /* FIPS 197 Appendix B states after ShiftRows for Rounds 1 to 9. */
        check_state(128'hd4bf5d30e0b452aeb84111f11e2798e5,
                    128'h046681e5e0cb199a48f8d37a2806264c,
                    "fips197_round1_shiftrows_to_mixcolumns");
        check_state(128'h49db873b453953897f02d2f177de961a,
                    128'h584dcaf11b4b5aacdbe7caa81b6bb0e5,
                    "fips197_round2_shiftrows_to_mixcolumns");
        check_state(128'hacc1d6b8efb55a7b1323cfdf457311b5,
                    128'h75ec0993200b633353c0cf7cbb25d0dc,
                    "fips197_round3_shiftrows_to_mixcolumns");
        check_state(128'h52a4c89485116a28e3cf2fd7f6505e07,
                    128'h0fd6daa9603138bf6fc0106b5eb31301,
                    "fips197_round4_shiftrows_to_mixcolumns");
        check_state(128'he1fb967ce8c8ae9b356cd2ba974ffb53,
                    128'h25d1a9adbd11d168b63a338e4c4cc0b0,
                    "fips197_round5_shiftrows_to_mixcolumns");
        check_state(128'ha14f3dfe78e803fc10d5a8df4c632923,
                    128'h4b868d6d2c4a8980339df4e837d218d8,
                    "fips197_round6_shiftrows_to_mixcolumns");
        check_state(128'hf783403f27433df09bb531ff54aba9d3,
                    128'h1415b5bf461615ec274656d7342ad843,
                    "fips197_round7_shiftrows_to_mixcolumns");
        check_state(128'hbe3bd4fed4e1f2c80a642cc0da83864d,
                    128'h00512fd1b1c889ff54766dcdfa1b99ea,
                    "fips197_round8_shiftrows_to_mixcolumns");
        check_state(128'h876e46a6f24ce78c4d904ad897ecc395,
                    128'h473794ed40d4e4a5a3703aa64c9f42bc,
                    "fips197_round9_shiftrows_to_mixcolumns");

        /* Additional deterministic edge-pattern tests. */
        check_state_auto(128'h00000000000000000000000000000000, "all_zero_state");
        check_state_auto(128'hffffffffffffffffffffffffffffffff, "all_one_state");
        check_state_auto(128'h000102030405060708090a0b0c0d0e0f, "ascending_bytes");
        check_state_auto(128'hffeeddccbbaa99887766554433221100, "descending_pattern");
        check_state_auto(128'h0123456789abcdeffedcba9876543210, "mixed_pattern_1");
        check_state_auto(128'h6bc1bee22e409f96e93d7e117393172a, "nist_plaintext_block_1");
        check_state_auto(128'hae2d8a571e03ac9c9eb76fac45af8e51, "nist_plaintext_block_2");

        $display("==============================================");
        $display("Full MixColumns Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: FULL MIXCOLUMNS UNIT TEST PASSED");
        end
        else
        begin
            $display("RESULT: FULL MIXCOLUMNS UNIT TEST FAILED");
        end

        $stop;
    end

endmodule
