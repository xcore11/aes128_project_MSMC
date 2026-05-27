# ============================================================
# File        : aes128_optimized.sdc
# Description : Timing constraints for AES-128 optimized design
# Target      : Quartus Timing Analyzer
#
# Notes:
#   - This assumes a 50 MHz input clock.
#   - Change the clock period to 10.000 ns if your real clock is 100 MHz.
# ============================================================

# 50 MHz system clock
create_clock -name clk -period 20.000 [get_ports {clk}]

# Let Quartus calculate appropriate setup/hold uncertainty
derive_clock_uncertainty

# Input delays relative to clk
set_input_delay  -clock clk -max 2.000 [get_ports {start plaintext[*] key[*]}]
set_input_delay  -clock clk -min 0.000 [get_ports {start plaintext[*] key[*]}]

# Output delays relative to clk
set_output_delay -clock clk -max 2.000 [get_ports {ciphertext[*] busy done}]
set_output_delay -clock clk -min 0.000 [get_ports {ciphertext[*] busy done}]

# Active-low asynchronous reset is not timed as a normal data input
set_false_path -from [get_ports {reset_n}]
