/**
 * @file tb_aes128_encrypt.sv
 * @brief Common AES-128 encryption testbench for baseline and optimized cores.
 *
 * This testbench reads AES-128 encryption test vectors from test_vectors.txt.
 * Each line in test_vectors.txt must contain:
 *
 *     key plaintext expected_ciphertext
 *
 * Example:
 *
 *     2b7e151628aed2a6abf7158809cf4f3c 6bc1bee22e409f96e93d7e117393172a 3ad77bb40d7a3660a89ecaf32466ef97
 *
 * This testbench can be used for both:
 *
 *     aes128_baseline
 *     aes128_optimized
 *
 * To select the DUT, change the `define section below.
 */

`timescale 1ns / 1ps

/*
 * ============================================================
 * DUT SELECTION
 * ============================================================
 *
 * Use only ONE of the following defines.
 *
 * For baseline:
 *     `define USE_BASELINE
 *
 * For optimized:
 *     `define USE_OPTIMIZED
 */

// `define USE_BASELINE
`define USE_OPTIMIZED

module tb_aes128_encrypt;

    /* Clock and reset signals */
    logic clk;
    logic reset_n;

    /* DUT input signals */
    logic         start;
    logic [127:0] plaintext;
    logic [127:0] key;

    /* DUT output signals */
    logic [127:0] ciphertext;
    logic         busy;
    logic         done;

    /* Test vector variables */
    logic [127:0] vector_key;
    logic [127:0] vector_plaintext;
    logic [127:0] expected_ciphertext;

    /* File and test counters */
    integer vector_file;
    integer scan_result;
    integer test_count;
    integer pass_count;
    integer fail_count;
    integer cycle_count;
    integer idle_wait_count;

    /* Clock and timeout settings */
    localparam integer CLK_PERIOD      = 10;
    localparam integer MAX_WAIT_CYCLES = 10000;
    localparam integer MAX_IDLE_CYCLES = 10000;

    /*
     * ============================================================
     * DUT INSTANTIATION
     * ============================================================
     *
     * Both baseline and optimized modules must use the same interface:
     *
     *     clk
     *     reset_n
     *     start
     *     plaintext
     *     key
     *     ciphertext
     *     busy
     *     done
     */

`ifdef USE_BASELINE

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

`elsif USE_OPTIMIZED

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

`else

    initial
    begin
        $display("ERROR: No DUT selected.");
        $display("Please define either USE_BASELINE or USE_OPTIMIZED.");
        $finish;
    end

`endif

    /**
     * @brief Clock generation.
     */
    initial
    begin
        clk = 1'b0;

        forever
        begin
            #(CLK_PERIOD / 2) clk = ~clk;
        end
    end

    /**
     * @brief Apply reset to the DUT.
     */
    task apply_reset;
    begin
        reset_n   = 1'b0;
        start     = 1'b0;
        plaintext = 128'h0;
        key       = 128'h0;

        repeat (5)
        begin
            @(posedge clk);
        end

        reset_n = 1'b1;

        repeat (5)
        begin
            @(posedge clk);
        end
    end
    endtask

    /**
     * @brief Wait until DUT is idle before starting a new test.
     *
     * This prevents the next vector from being applied while the optimized
     * core is still processing the previous vector.
     */
    task wait_until_idle;
    begin
        idle_wait_count = 0;

        while ((busy === 1'b1) && (idle_wait_count < MAX_IDLE_CYCLES))
        begin
            @(posedge clk);
            idle_wait_count = idle_wait_count + 1;
        end

        if (idle_wait_count >= MAX_IDLE_CYCLES)
        begin
            $display("ERROR: DUT stayed busy for too long before starting next test.");
            $display("Simulation stopped to prevent overlapping test vectors.");
            $finish;
        end

        repeat (1)
        begin
            @(posedge clk);
        end
    end
    endtask

    /**
     * @brief Run one AES-128 encryption test vector.
     *
     * @param input_key             128-bit AES key.
     * @param input_plaintext       128-bit plaintext.
     * @param input_expected_cipher Expected 128-bit ciphertext.
     */
    task run_single_test;
        input logic [127:0] input_key;
        input logic [127:0] input_plaintext;
        input logic [127:0] input_expected_cipher;

    begin
        /*
         * Make sure previous encryption has fully completed.
         */
        wait_until_idle();

        /*
         * Apply input vector.
         */
        key       = input_key;
        plaintext = input_plaintext;
        start     = 1'b0;

        @(posedge clk);

        /*
         * Start pulse: one clock cycle.
         */
        start = 1'b1;

        @(posedge clk);

        start = 1'b0;

        /*
         * Wait for done.
         */
        cycle_count = 0;

        while ((done !== 1'b1) && (cycle_count < MAX_WAIT_CYCLES))
        begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        test_count = test_count + 1;

        /*
         * Check result.
         */
        if (cycle_count >= MAX_WAIT_CYCLES)
        begin
            fail_count = fail_count + 1;

            $display("TEST %0d FAIL: Timeout waiting for done signal", test_count);
            $display("KEY        = %032h", input_key);
            $display("PLAINTEXT  = %032h", input_plaintext);
            $display("EXPECTED   = %032h", input_expected_cipher);
            $display("GOT        = %032h", ciphertext);

            /*
             * Recovery step:
             * Wait until busy clears before next vector.
             * This avoids comparing the previous result against the next test.
             */
            wait_until_idle();
        end
        else if (ciphertext === input_expected_cipher)
        begin
            pass_count = pass_count + 1;

            $display("TEST %0d PASS | cycles = %0d", test_count, cycle_count);
        end
        else
        begin
            fail_count = fail_count + 1;

            $display("TEST %0d FAIL: Ciphertext mismatch", test_count);
            $display("KEY        = %032h", input_key);
            $display("PLAINTEXT  = %032h", input_plaintext);
            $display("EXPECTED   = %032h", input_expected_cipher);
            $display("GOT        = %032h", ciphertext);
        end

        /*
         * Small gap before next test.
         */
        repeat (2)
        begin
            @(posedge clk);
        end
    end
    endtask

    /**
     * @brief Main test sequence.
     */
    initial
    begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        apply_reset();

        vector_file = $fopen("../../tb/test_vectors.txt", "r");

        if (vector_file == 0)
        begin
            $display("ERROR: Cannot open test_vectors.txt");
            $display("Make sure test_vectors.txt is in the ModelSim simulation working directory.");
            $display("Use 'pwd' in the ModelSim transcript to check the current directory.");
            $finish;
        end

        $display("==============================================");
        $display("AES-128 Encryption Testbench Started");
`ifdef USE_BASELINE
        $display("DUT selected : aes128_baseline");
`elsif USE_OPTIMIZED
        $display("DUT selected : aes128_optimized");
`endif
        $display("Max wait     : %0d cycles", MAX_WAIT_CYCLES);
        $display("==============================================");

        while (!$feof(vector_file))
        begin
            scan_result = $fscanf(
                vector_file,
                "%h %h %h\n",
                vector_key,
                vector_plaintext,
                expected_ciphertext
            );

            if (scan_result == 3)
            begin
                run_single_test(
                    vector_key,
                    vector_plaintext,
                    expected_ciphertext
                );
            end
        end

        $fclose(vector_file);

        $display("==============================================");
        $display("AES-128 Encryption Testbench Summary");
        $display("==============================================");
        $display("Total tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
        begin
            $display("RESULT: ALL AES-128 TEST VECTORS PASSED");
        end
        else
        begin
            $display("RESULT: AES-128 TEST FAILED");
        end

        $finish;
    end

endmodule