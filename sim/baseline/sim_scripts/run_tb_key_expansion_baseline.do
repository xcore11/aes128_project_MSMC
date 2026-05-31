# Auto-generated ModelSim script for tb_key_expansion_baseline
# Run this from the project root folder.

onbreak {resume}
transcript on

file mkdir "sim/baseline/logs"
file mkdir "sim/baseline/waveforms"

transcript file "sim/baseline/logs/tb_key_expansion_baseline_log.txt"

echo "=============================================="
echo "RUNNING tb_key_expansion_baseline"
echo "=============================================="

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# Compile all RTL files for this design, then this testbench.
vlog -sv [glob "rtl/baseline/*.sv"]
vlog -sv "tb/baseline/tb_key_expansion.sv"

# Save waveform database to the correct folder.
vsim -wlf "sim/baseline/waveforms/tb_key_expansion_baseline.wlf" work.tb_key_expansion

# Add all testbench and DUT signals into the waveform.
view wave
add wave -r sim:/tb_key_expansion/*

run -all

# Force waveform/log database to close cleanly before the next test.
quit -sim
transcript file ""

echo "=============================================="
echo "FINISHED tb_key_expansion_baseline"
echo "Log      : sim/baseline/logs/tb_key_expansion_baseline_log.txt"
echo "Waveform : sim/baseline/waveforms/tb_key_expansion_baseline.wlf"
echo "=============================================="
