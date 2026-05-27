# ============================================================
# File        : aes128_baseline.sdc
# Description : Timing constraints for AES-128 baseline design
# Top entity  : aes128_baseline
# Clock       : clk, assumed 50 MHz board clock
# ============================================================

# Main system clock.
# 20.000 ns period = 50 MHz.
# Change to 10.000 if your real clock is 100 MHz.
create_clock -name clk -period 20.000 [get_ports {clk}]

# Let Quartus/TimeQuest estimate clock uncertainty for setup/hold analysis.
derive_clock_uncertainty

# ------------------------------------------------------------
# Input delay constraints
# ------------------------------------------------------------
# These constrain external AES control/data inputs relative to clk.
# The 2 ns value is a reasonable simple assumption for this project.
# It means external input data is assumed to arrive 2 ns after the clock edge.
set_input_delay  -clock clk -max 2.000 [get_ports {start plaintext[*] key[*]}]
set_input_delay  -clock clk -min 0.000 [get_ports {start plaintext[*] key[*]}]

# ------------------------------------------------------------
# Output delay constraints
# ------------------------------------------------------------
# These constrain AES output signals relative to clk.
# The 2 ns value reserves timing margin for external receiving logic.
set_output_delay -clock clk -max 2.000 [get_ports {ciphertext[*] busy done}]
set_output_delay -clock clk -min 0.000 [get_ports {ciphertext[*] busy done}]

# ------------------------------------------------------------
# Reset constraint
# ------------------------------------------------------------
# reset_n is an active-low asynchronous reset in aes_core.sv.
# Do not time it as normal synchronous data.
set_false_path -from [get_ports {reset_n}]

# ============================================================
# End of constraints
# ============================================================
