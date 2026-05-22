/**
 * @file tb_mix_columns_one_column.sv
 * @brief Unit testbench for AES MixColumns one-column module.
 *
 * This testbench verifies the 32-bit one-column MixColumns block.
 * It includes fixed FIPS/project examples and additional deterministic
 * cases calculated by a reference MixColumns function inside the testbench.
 */

`timescale 1ns/1ps

module tb_mix_columns_one_column;

    logic [31:0] col_in;
    logic [31:0] col_out;

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer i;

    mix_columns_one_column dut
    (
        .col_in  (col_in),
        .col_out (col_out)
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

    task check_column;
        input logic [31:0] input_column;
        input logic [31:0] expected_column;
        input string       test_name;
    begin
        col_in = input_column;
        #1;

        test_count = test_count + 1;

        if (col_out === expected_column)
        begin
            pass_count = pass_count + 1;
            $display("TEST %0d PASS: %s | %08h -> %08h", test_count, test_name, input_column, col_out);
        end
        else
        begin
            fail_count = fail_count + 1;
            $display("TEST %0d FAIL: %s", test_count, test_name);
            $display("INPUT    = %08h", input_column);
            $display("EXPECTED = %08h", expected_column);
            $display("GOT      = %08h", col_out);
        end
    end
    endtask

    task check_column_auto;
        input logic [31:0] input_column;
        input string       test_name;
    begin
        check_column(input_column, ref_mix_column(input_column), test_name);
    end
    endtask

    initial
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        col_in     = 32'h0;

        $display("==============================================");
        $display("MixColumns One-Column Unit Test Started");
        $display("==============================================");

        /* Project/FIPS-style fixed examples. */
        check_column(32'h12c994a8, 32'h58940b20, "project_example_col0");
        check_column(32'h25dade75, 32'h9486c781, "project_example_col1");
        check_column(32'hc15f005f, 32'h27207fb9, "project_example_col2");
        check_column(32'h3f8e442c, 32'h9fd84dd3, "project_example_col3");

        /* FIPS 197 Appendix B, Round 1 ShiftRows columns. */
        check_column(32'hd4bf5d30, 32'h046681e5, "fips_round1_column0");
        check_column(32'he0b452ae, 32'he0cb199a, "fips_round1_column1");
        check_column(32'hb84111f1, 32'h48f8d37a, "fips_round1_column2");
        check_column(32'h1e2798e5, 32'h2806264c, "fips_round1_column3");

        /* Additional deterministic reference-based cases. */
        check_column_auto(32'h00000000, "zero_column");
        check_column_auto(32'hffffffff, "all_ones_column");
        check_column_auto(32'h00010203, "ascending_00_03");
        check_column_auto(32'h03020100, "descending_03_00");
        check_column_auto(32'h01000000, "single_bit_msb_byte");
        check_column_auto(32'h00000001, "single_bit_lsb_byte");
        check_column_auto(32'h57ae47e8, "gf_xtime_stress_pattern");
        check_column_auto(32'h6bc1bee2, "nist_plaintext_column0");
        check_column_auto(32'h2e409f96, "nist_plaintext_column1");
        check_column_auto(32'he93d7e11, "nist_plaintext_column2");
        check_column_auto(32'h7393172a, "nist_plaintext_column3");
        check_column_auto(32'h01234567, "mixed_pattern_1");
        check_column_auto(32'h89abcdef, "mixed_pattern_2");
        check_column_auto(32'hfedcba98, "mixed_pattern_3");
        check_column_auto(32'h76543210, "mixed_pattern_4");

        $display("==============================================");
        $display("MixColumns One-Column Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: MIXCOLUMNS ONE-COLUMN UNIT TEST PASSED");
        end
        else
        begin
            $display("RESULT: MIXCOLUMNS ONE-COLUMN UNIT TEST FAILED");
        end

        $stop;
    end

endmodule
