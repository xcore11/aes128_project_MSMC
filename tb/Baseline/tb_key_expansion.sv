/**
 * @file tb_key_expansion.sv
 * @brief Unit testbench for baseline AES-128 keyexpansion module.
 *
 * This testbench checks all ten one-round key-expansion steps for
 * the FIPS 197 Appendix A.1 AES-128 key schedule example.
 */

`timescale 1ns/1ps

module tb_key_expansion;

    logic [127:0] key_in;
    logic [7:0]   rcon_byte;
    logic [127:0] key_out;

    integer test_count;
    integer pass_count;
    integer fail_count;

    keyexpansion dut
    (
        .key_in    (key_in),
        .rcon_byte (rcon_byte),
        .key_out   (key_out)
    );

    task check_key;
        input logic [127:0] input_key;
        input logic [7:0]   input_rcon;
        input logic [127:0] expected_key;
        input string        test_name;
    begin
        key_in    = input_key;
        rcon_byte = input_rcon;
        #1;

        test_count = test_count + 1;

        $display("----------------------------------------------");
        $display("TEST %0d: %s", test_count, test_name);
        $display("Operation = AES-128 one-round key expansion");
        $display("RCON      = %02h", input_rcon);
        $display("KEY_IN    = %032h", input_key);
        $display("EXPECTED  = %032h", expected_key);
        $display("GOT       = %032h", key_out);

        if (key_out === expected_key)
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
        key_in     = 128'h0;
        rcon_byte  = 8'h0;

        $display("==============================================");
        $display("AES-128 KeyExpansion Unit Test Started");
        $display("==============================================");

        check_key(128'h2b7e151628aed2a6abf7158809cf4f3c, 8'h01,
                  128'ha0fafe1788542cb123a339392a6c7605, "K0_to_K1");
        check_key(128'ha0fafe1788542cb123a339392a6c7605, 8'h02,
                  128'hf2c295f27a96b9435935807a7359f67f, "K1_to_K2");
        check_key(128'hf2c295f27a96b9435935807a7359f67f, 8'h04,
                  128'h3d80477d4716fe3e1e237e446d7a883b, "K2_to_K3");
        check_key(128'h3d80477d4716fe3e1e237e446d7a883b, 8'h08,
                  128'hef44a541a8525b7fb671253bdb0bad00, "K3_to_K4");
        check_key(128'hef44a541a8525b7fb671253bdb0bad00, 8'h10,
                  128'hd4d1c6f87c839d87caf2b8bc11f915bc, "K4_to_K5");
        check_key(128'hd4d1c6f87c839d87caf2b8bc11f915bc, 8'h20,
                  128'h6d88a37a110b3efddbf98641ca0093fd, "K5_to_K6");
        check_key(128'h6d88a37a110b3efddbf98641ca0093fd, 8'h40,
                  128'h4e54f70e5f5fc9f384a64fb24ea6dc4f, "K6_to_K7");
        check_key(128'h4e54f70e5f5fc9f384a64fb24ea6dc4f, 8'h80,
                  128'head27321b58dbad2312bf5607f8d292f, "K7_to_K8");
        check_key(128'head27321b58dbad2312bf5607f8d292f, 8'h1b,
                  128'hac7766f319fadc2128d12941575c006e, "K8_to_K9");
        check_key(128'hac7766f319fadc2128d12941575c006e, 8'h36,
                  128'hd014f9a8c9ee2589e13f0cc8b6630ca6, "K9_to_K10");

        $display("==============================================");
        $display("KeyExpansion Summary");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: KEYEXPANSION UNIT TEST PASSED");
        end
        else
        begin
            $display("RESULT: KEYEXPANSION UNIT TEST FAILED");
        end

        $stop;
    end

endmodule
