`timescale 1ns/1ps

module tb_live_demo;

    logic clk;
    logic reset_n;
    logic start;

    logic [127:0] plaintext;
    logic [127:0] key;
    logic [127:0] ciphertext;

    logic busy;
    logic done;

    // Change this module name and port names if your top-level is different
    aes128_baseline dut
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

    initial
    begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial
    begin
        start = 1'b0;
        reset_n = 1'b0;
        plaintext = 128'h0;
        key = 128'h0;

        if (!$value$plusargs("PT=%h", plaintext))
        begin
            $display("ERROR: Missing plaintext input.");
            $display("Use: vsim work.tb_live_demo +PT=<128-bit hex> +KEY=<128-bit hex>");
            $finish;
        end

        if (!$value$plusargs("KEY=%h", key))
        begin
            $display("ERROR: Missing key input.");
            $display("Use: vsim work.tb_live_demo +PT=<128-bit hex> +KEY=<128-bit hex>");
            $finish;
        end

        repeat (5) @(posedge clk);
        reset_n = 1'b1;

        repeat (2) @(posedge clk);

        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);

        @(posedge clk);

        $display("");
        $display("==============================================");
        $display(" AES-128 LIVE DEMONSTRATION RESULT");
        $display("==============================================");
        $display("PLAINTEXT  = %032h", plaintext);
        $display("KEY        = %032h", key);
        $display("CIPHERTEXT = %032h", ciphertext);
        $display("==============================================");
        $display("PASS: AES-128 encryption completed.");
        $display("");

        $finish;
    end

endmodule