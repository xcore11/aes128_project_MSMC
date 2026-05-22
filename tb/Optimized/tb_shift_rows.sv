/**
 * @file tb_shift_rows.sv
 * @brief Unit testbench for AES ShiftRows module.
 *
 * This testbench checks fixed FIPS 197 intermediate states and
 * additional deterministic byte-ordering patterns.
 */

`timescale 1ns/1ps

module tb_shift_rows;

    logic [127:0] state_in;
    logic [127:0] state_out;

    integer test_count;
    integer pass_count;
    integer fail_count;

    shift_rows dut
    (
        .state_in  (state_in),
        .state_out (state_out)
    );

    function automatic logic [127:0] ref_shift_rows;
        input logic [127:0] state;
        logic [7:0] b [0:15];
    begin
        {b[0],  b[1],  b[2],  b[3],
         b[4],  b[5],  b[6],  b[7],
         b[8],  b[9],  b[10], b[11],
         b[12], b[13], b[14], b[15]} = state;

        ref_shift_rows = {
            b[0],  b[5],  b[10], b[15],
            b[4],  b[9],  b[14], b[3],
            b[8],  b[13], b[2],  b[7],
            b[12], b[1],  b[6],  b[11]
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
        check_state(input_state, ref_shift_rows(input_state), test_name);
    end
    endtask

    initial
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        state_in   = 128'h0;

        $display("==============================================");
        $display("ShiftRows Unit Test Started");
        $display("==============================================");

        /* Deterministic byte-ordering patterns. */
        check_state(128'h000102030405060708090a0b0c0d0e0f,
                    128'h00050a0f04090e03080d02070c01060b,
                    "ascending_bytes_fixed_expected");
        check_state_auto(128'hffffffffffffffffffffffffffffffff,
                         "all_ones");
        check_state_auto(128'h00000000000000000000000000000000,
                         "all_zeroes");
        check_state_auto(128'hffeeddccbbaa99887766554433221100,
                         "descending_pattern");
        check_state_auto(128'h0123456789abcdeffedcba9876543210,
                         "mixed_pattern_1");

        /* FIPS 197 Appendix B states after SubBytes for Rounds 1 to 10. */
        check_state(128'hd42711aee0bf98f1b8b45de51e415230,
                    128'hd4bf5d30e0b452aeb84111f11e2798e5,
                    "fips197_round1_subbytes_to_shiftrows");
        check_state(128'h49ded28945db96f17f39871a7702533b,
                    128'h49db873b453953897f02d2f177de961a,
                    "fips197_round2_subbytes_to_shiftrows");
        check_state(128'hac73cf7befc111df13b5d6b545235ab8,
                    128'hacc1d6b8efb55a7b1323cfdf457311b5,
                    "fips197_round3_subbytes_to_shiftrows");
        check_state(128'h52502f2885a45ed7e311c807f6cf6a94,
                    128'h52a4c89485116a28e3cf2fd7f6505e07,
                    "fips197_round4_subbytes_to_shiftrows");
        check_state(128'he14fd29be8fbfbba35c89653976cae7c,
                    128'he1fb967ce8c8ae9b356cd2ba974ffb53,
                    "fips197_round5_subbytes_to_shiftrows");
        check_state(128'ha163a8fc784f29df10e83d234cd503fe,
                    128'ha14f3dfe78e803fc10d5a8df4c632923,
                    "fips197_round6_subbytes_to_shiftrows");
        check_state(128'hf7ab31f02783a9ff9b4340d354b53d3f,
                    128'hf783403f27433df09bb531ff54aba9d3,
                    "fips197_round7_subbytes_to_shiftrows");
        check_state(128'hbe832cc8d43b86c00ae1d44dda64f2fe,
                    128'hbe3bd4fed4e1f2c80a642cc0da83864d,
                    "fips197_round8_subbytes_to_shiftrows");
        check_state(128'h87ec4a8cf26ec3d84d4c46959790e7a6,
                    128'h876e46a6f24ce78c4d904ad897ecc395,
                    "fips197_round9_subbytes_to_shiftrows");
        check_state(128'he9098972cb31075f3d327d94af2e2cb5,
                    128'he9317db5cb322c723d2e895faf090794,
                    "fips197_round10_subbytes_to_shiftrows");

        $display("==============================================");
        $display("ShiftRows Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: SHIFTROWS UNIT TEST PASSED");
        end
        else
        begin
            $display("RESULT: SHIFTROWS UNIT TEST FAILED");
        end

        $stop;
    end

endmodule
