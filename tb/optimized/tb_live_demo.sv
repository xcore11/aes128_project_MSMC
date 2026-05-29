`timescale 1ns/1ps

module tb_live_demo;

    localparam integer TIMEOUT_CYCLES = 5000;

    // ============================================================
    // Type the demo input here
    // ============================================================
    localparam logic [127:0] DEMO_PLAINTEXT =
        128'he5ce68e1decc8d3076df6e0ecf22c44b;

    localparam logic [127:0] DEMO_KEY =
        128'ha407c4ca6f08d371a3f8df364428dcd1;

    localparam logic [127:0] EXPECTED_CIPHERTEXT =
        128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    localparam CHECK_EXPECTED = 1'b1;

    // ============================================================
    // Testbench signals
    // ============================================================
    logic clk;
    logic reset_n;
    logic start;

    logic [127:0] plaintext;
    logic [127:0] key;
    logic [127:0] ciphertext;

    logic busy;
    logic done;
    logic done_seen;

    integer cycle_count;
    integer done_cycle;

    // ============================================================
    // Optimized AES-128 design
    // ============================================================
    aes128_optimized dut
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

    // ============================================================
    // Clock generation
    // ============================================================
    initial
    begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Latch done pulse
    // ============================================================
    always_ff @(posedge clk or negedge reset_n)
    begin
        if (reset_n == 1'b0)
        begin
            done_seen  <= 1'b0;
            done_cycle <= -1;
        end
        else
        begin
            if (done == 1'b1 && done_seen == 1'b0)
            begin
                done_seen  <= 1'b1;
                done_cycle <= cycle_count;
            end
        end
    end

    // ============================================================
    // Live demo sequence
    // ============================================================
    initial
    begin
        start = 1'b0;
        reset_n = 1'b0;

        plaintext = DEMO_PLAINTEXT;
        key       = DEMO_KEY;

        cycle_count = 0;

        // Hold reset for a few cycles
        repeat (5) @(posedge clk);

        // Release reset away from the positive edge
        @(negedge clk);
        reset_n = 1'b1;

        repeat (3) @(posedge clk);

        // Apply start pulse safely
        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Wait for optimized design to finish
        while (done_seen == 1'b0 && cycle_count < TIMEOUT_CYCLES)
        begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        if (cycle_count >= TIMEOUT_CYCLES)
        begin
            $display("");
            $display("==============================================");
            $display(" AES-128 OPTIMIZED LIVE DEMONSTRATION RESULT");
            $display("==============================================");
            $display("ERROR: Timeout waiting for optimized AES design to finish.");
            $display("Done seen = %b", done_seen);
            $display("Busy      = %b", busy);
            $display("Start     = %b", start);
            $display("Reset_n   = %b", reset_n);
            $display("==============================================");
            $display("");
            $finish;
        end

        @(posedge clk);

        $display("");
        $display("==============================================");
        $display(" AES-128 OPTIMIZED LIVE DEMONSTRATION RESULT");
        $display("==============================================");
        $display("PLAINTEXT            = %032h", plaintext);
        $display("KEY                  = %032h", key);
        $display("----------------------------------------------");
        $display("OPTIMIZED CIPHERTEXT = %032h", ciphertext);
        $display("DONE CYCLE           = %0d", done_cycle);
        $display("----------------------------------------------");

        if (CHECK_EXPECTED == 1'b1)
        begin
            $display("EXPECTED CIPHERTEXT  = %032h", EXPECTED_CIPHERTEXT);

            if (ciphertext == EXPECTED_CIPHERTEXT)
            begin
                $display("PASS: Optimized design matches the expected ciphertext.");
            end
            else
            begin
                $display("FAIL: Optimized design does not match the expected ciphertext.");
            end
        end
        else
        begin
            $display("PASS: Optimized AES-128 encryption completed.");
        end

        $display("==============================================");
        $display("");

        $finish;
    end

endmodule