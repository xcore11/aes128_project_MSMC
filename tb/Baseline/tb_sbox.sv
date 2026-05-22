/**
 * @file tb_sbox.sv
 * @brief Exhaustive unit testbench for AES S-box module.
 *
 * This checks all 256 possible byte inputs against the official AES S-box.
 */

`timescale 1ns/1ps

module tb_sbox;

    logic [7:0] in_byte;
    logic [7:0] out_byte;

    integer i;
    integer pass_count;
    integer fail_count;

    sbox dut
    (
        .in_byte  (in_byte),
        .out_byte (out_byte)
    );

    /**
     * @brief Reference AES S-box table.
     */
    function automatic logic [7:0] ref_sbox;
        input logic [7:0] value;
    begin
        case (value)
            8'h00: ref_sbox = 8'h63;
            8'h01: ref_sbox = 8'h7c;
            8'h02: ref_sbox = 8'h77;
            8'h03: ref_sbox = 8'h7b;
            8'h04: ref_sbox = 8'hf2;
            8'h05: ref_sbox = 8'h6b;
            8'h06: ref_sbox = 8'h6f;
            8'h07: ref_sbox = 8'hc5;
            8'h08: ref_sbox = 8'h30;
            8'h09: ref_sbox = 8'h01;
            8'h0a: ref_sbox = 8'h67;
            8'h0b: ref_sbox = 8'h2b;
            8'h0c: ref_sbox = 8'hfe;
            8'h0d: ref_sbox = 8'hd7;
            8'h0e: ref_sbox = 8'hab;
            8'h0f: ref_sbox = 8'h76;
            8'h10: ref_sbox = 8'hca;
            8'h11: ref_sbox = 8'h82;
            8'h12: ref_sbox = 8'hc9;
            8'h13: ref_sbox = 8'h7d;
            8'h14: ref_sbox = 8'hfa;
            8'h15: ref_sbox = 8'h59;
            8'h16: ref_sbox = 8'h47;
            8'h17: ref_sbox = 8'hf0;
            8'h18: ref_sbox = 8'had;
            8'h19: ref_sbox = 8'hd4;
            8'h1a: ref_sbox = 8'ha2;
            8'h1b: ref_sbox = 8'haf;
            8'h1c: ref_sbox = 8'h9c;
            8'h1d: ref_sbox = 8'ha4;
            8'h1e: ref_sbox = 8'h72;
            8'h1f: ref_sbox = 8'hc0;
            8'h20: ref_sbox = 8'hb7;
            8'h21: ref_sbox = 8'hfd;
            8'h22: ref_sbox = 8'h93;
            8'h23: ref_sbox = 8'h26;
            8'h24: ref_sbox = 8'h36;
            8'h25: ref_sbox = 8'h3f;
            8'h26: ref_sbox = 8'hf7;
            8'h27: ref_sbox = 8'hcc;
            8'h28: ref_sbox = 8'h34;
            8'h29: ref_sbox = 8'ha5;
            8'h2a: ref_sbox = 8'he5;
            8'h2b: ref_sbox = 8'hf1;
            8'h2c: ref_sbox = 8'h71;
            8'h2d: ref_sbox = 8'hd8;
            8'h2e: ref_sbox = 8'h31;
            8'h2f: ref_sbox = 8'h15;
            8'h30: ref_sbox = 8'h04;
            8'h31: ref_sbox = 8'hc7;
            8'h32: ref_sbox = 8'h23;
            8'h33: ref_sbox = 8'hc3;
            8'h34: ref_sbox = 8'h18;
            8'h35: ref_sbox = 8'h96;
            8'h36: ref_sbox = 8'h05;
            8'h37: ref_sbox = 8'h9a;
            8'h38: ref_sbox = 8'h07;
            8'h39: ref_sbox = 8'h12;
            8'h3a: ref_sbox = 8'h80;
            8'h3b: ref_sbox = 8'he2;
            8'h3c: ref_sbox = 8'heb;
            8'h3d: ref_sbox = 8'h27;
            8'h3e: ref_sbox = 8'hb2;
            8'h3f: ref_sbox = 8'h75;
            8'h40: ref_sbox = 8'h09;
            8'h41: ref_sbox = 8'h83;
            8'h42: ref_sbox = 8'h2c;
            8'h43: ref_sbox = 8'h1a;
            8'h44: ref_sbox = 8'h1b;
            8'h45: ref_sbox = 8'h6e;
            8'h46: ref_sbox = 8'h5a;
            8'h47: ref_sbox = 8'ha0;
            8'h48: ref_sbox = 8'h52;
            8'h49: ref_sbox = 8'h3b;
            8'h4a: ref_sbox = 8'hd6;
            8'h4b: ref_sbox = 8'hb3;
            8'h4c: ref_sbox = 8'h29;
            8'h4d: ref_sbox = 8'he3;
            8'h4e: ref_sbox = 8'h2f;
            8'h4f: ref_sbox = 8'h84;
            8'h50: ref_sbox = 8'h53;
            8'h51: ref_sbox = 8'hd1;
            8'h52: ref_sbox = 8'h00;
            8'h53: ref_sbox = 8'hed;
            8'h54: ref_sbox = 8'h20;
            8'h55: ref_sbox = 8'hfc;
            8'h56: ref_sbox = 8'hb1;
            8'h57: ref_sbox = 8'h5b;
            8'h58: ref_sbox = 8'h6a;
            8'h59: ref_sbox = 8'hcb;
            8'h5a: ref_sbox = 8'hbe;
            8'h5b: ref_sbox = 8'h39;
            8'h5c: ref_sbox = 8'h4a;
            8'h5d: ref_sbox = 8'h4c;
            8'h5e: ref_sbox = 8'h58;
            8'h5f: ref_sbox = 8'hcf;
            8'h60: ref_sbox = 8'hd0;
            8'h61: ref_sbox = 8'hef;
            8'h62: ref_sbox = 8'haa;
            8'h63: ref_sbox = 8'hfb;
            8'h64: ref_sbox = 8'h43;
            8'h65: ref_sbox = 8'h4d;
            8'h66: ref_sbox = 8'h33;
            8'h67: ref_sbox = 8'h85;
            8'h68: ref_sbox = 8'h45;
            8'h69: ref_sbox = 8'hf9;
            8'h6a: ref_sbox = 8'h02;
            8'h6b: ref_sbox = 8'h7f;
            8'h6c: ref_sbox = 8'h50;
            8'h6d: ref_sbox = 8'h3c;
            8'h6e: ref_sbox = 8'h9f;
            8'h6f: ref_sbox = 8'ha8;
            8'h70: ref_sbox = 8'h51;
            8'h71: ref_sbox = 8'ha3;
            8'h72: ref_sbox = 8'h40;
            8'h73: ref_sbox = 8'h8f;
            8'h74: ref_sbox = 8'h92;
            8'h75: ref_sbox = 8'h9d;
            8'h76: ref_sbox = 8'h38;
            8'h77: ref_sbox = 8'hf5;
            8'h78: ref_sbox = 8'hbc;
            8'h79: ref_sbox = 8'hb6;
            8'h7a: ref_sbox = 8'hda;
            8'h7b: ref_sbox = 8'h21;
            8'h7c: ref_sbox = 8'h10;
            8'h7d: ref_sbox = 8'hff;
            8'h7e: ref_sbox = 8'hf3;
            8'h7f: ref_sbox = 8'hd2;
            8'h80: ref_sbox = 8'hcd;
            8'h81: ref_sbox = 8'h0c;
            8'h82: ref_sbox = 8'h13;
            8'h83: ref_sbox = 8'hec;
            8'h84: ref_sbox = 8'h5f;
            8'h85: ref_sbox = 8'h97;
            8'h86: ref_sbox = 8'h44;
            8'h87: ref_sbox = 8'h17;
            8'h88: ref_sbox = 8'hc4;
            8'h89: ref_sbox = 8'ha7;
            8'h8a: ref_sbox = 8'h7e;
            8'h8b: ref_sbox = 8'h3d;
            8'h8c: ref_sbox = 8'h64;
            8'h8d: ref_sbox = 8'h5d;
            8'h8e: ref_sbox = 8'h19;
            8'h8f: ref_sbox = 8'h73;
            8'h90: ref_sbox = 8'h60;
            8'h91: ref_sbox = 8'h81;
            8'h92: ref_sbox = 8'h4f;
            8'h93: ref_sbox = 8'hdc;
            8'h94: ref_sbox = 8'h22;
            8'h95: ref_sbox = 8'h2a;
            8'h96: ref_sbox = 8'h90;
            8'h97: ref_sbox = 8'h88;
            8'h98: ref_sbox = 8'h46;
            8'h99: ref_sbox = 8'hee;
            8'h9a: ref_sbox = 8'hb8;
            8'h9b: ref_sbox = 8'h14;
            8'h9c: ref_sbox = 8'hde;
            8'h9d: ref_sbox = 8'h5e;
            8'h9e: ref_sbox = 8'h0b;
            8'h9f: ref_sbox = 8'hdb;
            8'ha0: ref_sbox = 8'he0;
            8'ha1: ref_sbox = 8'h32;
            8'ha2: ref_sbox = 8'h3a;
            8'ha3: ref_sbox = 8'h0a;
            8'ha4: ref_sbox = 8'h49;
            8'ha5: ref_sbox = 8'h06;
            8'ha6: ref_sbox = 8'h24;
            8'ha7: ref_sbox = 8'h5c;
            8'ha8: ref_sbox = 8'hc2;
            8'ha9: ref_sbox = 8'hd3;
            8'haa: ref_sbox = 8'hac;
            8'hab: ref_sbox = 8'h62;
            8'hac: ref_sbox = 8'h91;
            8'had: ref_sbox = 8'h95;
            8'hae: ref_sbox = 8'he4;
            8'haf: ref_sbox = 8'h79;
            8'hb0: ref_sbox = 8'he7;
            8'hb1: ref_sbox = 8'hc8;
            8'hb2: ref_sbox = 8'h37;
            8'hb3: ref_sbox = 8'h6d;
            8'hb4: ref_sbox = 8'h8d;
            8'hb5: ref_sbox = 8'hd5;
            8'hb6: ref_sbox = 8'h4e;
            8'hb7: ref_sbox = 8'ha9;
            8'hb8: ref_sbox = 8'h6c;
            8'hb9: ref_sbox = 8'h56;
            8'hba: ref_sbox = 8'hf4;
            8'hbb: ref_sbox = 8'hea;
            8'hbc: ref_sbox = 8'h65;
            8'hbd: ref_sbox = 8'h7a;
            8'hbe: ref_sbox = 8'hae;
            8'hbf: ref_sbox = 8'h08;
            8'hc0: ref_sbox = 8'hba;
            8'hc1: ref_sbox = 8'h78;
            8'hc2: ref_sbox = 8'h25;
            8'hc3: ref_sbox = 8'h2e;
            8'hc4: ref_sbox = 8'h1c;
            8'hc5: ref_sbox = 8'ha6;
            8'hc6: ref_sbox = 8'hb4;
            8'hc7: ref_sbox = 8'hc6;
            8'hc8: ref_sbox = 8'he8;
            8'hc9: ref_sbox = 8'hdd;
            8'hca: ref_sbox = 8'h74;
            8'hcb: ref_sbox = 8'h1f;
            8'hcc: ref_sbox = 8'h4b;
            8'hcd: ref_sbox = 8'hbd;
            8'hce: ref_sbox = 8'h8b;
            8'hcf: ref_sbox = 8'h8a;
            8'hd0: ref_sbox = 8'h70;
            8'hd1: ref_sbox = 8'h3e;
            8'hd2: ref_sbox = 8'hb5;
            8'hd3: ref_sbox = 8'h66;
            8'hd4: ref_sbox = 8'h48;
            8'hd5: ref_sbox = 8'h03;
            8'hd6: ref_sbox = 8'hf6;
            8'hd7: ref_sbox = 8'h0e;
            8'hd8: ref_sbox = 8'h61;
            8'hd9: ref_sbox = 8'h35;
            8'hda: ref_sbox = 8'h57;
            8'hdb: ref_sbox = 8'hb9;
            8'hdc: ref_sbox = 8'h86;
            8'hdd: ref_sbox = 8'hc1;
            8'hde: ref_sbox = 8'h1d;
            8'hdf: ref_sbox = 8'h9e;
            8'he0: ref_sbox = 8'he1;
            8'he1: ref_sbox = 8'hf8;
            8'he2: ref_sbox = 8'h98;
            8'he3: ref_sbox = 8'h11;
            8'he4: ref_sbox = 8'h69;
            8'he5: ref_sbox = 8'hd9;
            8'he6: ref_sbox = 8'h8e;
            8'he7: ref_sbox = 8'h94;
            8'he8: ref_sbox = 8'h9b;
            8'he9: ref_sbox = 8'h1e;
            8'hea: ref_sbox = 8'h87;
            8'heb: ref_sbox = 8'he9;
            8'hec: ref_sbox = 8'hce;
            8'hed: ref_sbox = 8'h55;
            8'hee: ref_sbox = 8'h28;
            8'hef: ref_sbox = 8'hdf;
            8'hf0: ref_sbox = 8'h8c;
            8'hf1: ref_sbox = 8'ha1;
            8'hf2: ref_sbox = 8'h89;
            8'hf3: ref_sbox = 8'h0d;
            8'hf4: ref_sbox = 8'hbf;
            8'hf5: ref_sbox = 8'he6;
            8'hf6: ref_sbox = 8'h42;
            8'hf7: ref_sbox = 8'h68;
            8'hf8: ref_sbox = 8'h41;
            8'hf9: ref_sbox = 8'h99;
            8'hfa: ref_sbox = 8'h2d;
            8'hfb: ref_sbox = 8'h0f;
            8'hfc: ref_sbox = 8'hb0;
            8'hfd: ref_sbox = 8'h54;
            8'hfe: ref_sbox = 8'hbb;
            8'hff: ref_sbox = 8'h16;
            default: ref_sbox = 8'h00;
        endcase
    end
    endfunction

    initial
    begin
        pass_count = 0;
        fail_count = 0;
        in_byte    = 8'h00;

        $display("==============================================");
        $display("AES S-box Exhaustive Unit Test Started");
        $display("==============================================");

        for (i = 0; i < 256; i = i + 1)
        begin
            in_byte = i[7:0];
            #1;

            if (out_byte === ref_sbox(i[7:0]))
            begin
                pass_count = pass_count + 1;
            end
            else
            begin
                fail_count = fail_count + 1;
                $display("FAIL: SBOX(%02h) expected %02h, got %02h",
                         i[7:0], ref_sbox(i[7:0]), out_byte);
            end
        end

        $display("==============================================");
        $display("S-box Summary");
        $display("Total tests : 256");
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: SBOX UNIT TEST PASSED");
        end
        else
        begin
            $display("RESULT: SBOX UNIT TEST FAILED");
        end

        $stop;
    end

endmodule
