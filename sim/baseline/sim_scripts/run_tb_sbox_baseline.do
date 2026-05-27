# Auto-generated ModelSim script for tb_sbox_baseline
# Run this from the project root folder.

onbreak {resume}
transcript on

file mkdir "sim/baseline/logs"
file mkdir "sim/baseline/waveforms"

transcript file "sim/baseline/logs/tb_sbox_baseline_log.txt"

echo "=============================================="
echo "RUNNING tb_sbox_baseline"
echo "=============================================="

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# Compile all RTL files for this design, then this testbench.
vlog -sv [glob "rtl/baseline/*.sv"]
vlog -sv "tb/baseline/tb_sbox.sv"

# Save waveform database to the correct folder.
vsim -wlf "sim/baseline/waveforms/tb_sbox_baseline.wlf" work.tb_sbox

# Add all testbench and DUT signals into the waveform.
view wave
add wave -r sim:/tb_sbox/*

run -all

# Force waveform/log database to close cleanly before the next test.
quit -sim
transcript file ""

echo "=============================================="
echo "FINISHED tb_sbox_baseline"
echo "Log      : sim/baseline/logs/tb_sbox_baseline_log.txt"
echo "Waveform : sim/baseline/waveforms/tb_sbox_baseline.wlf"
echo "=============================================="
