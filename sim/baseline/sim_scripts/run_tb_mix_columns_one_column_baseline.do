# Auto-generated ModelSim script for tb_mix_columns_one_column_baseline
# Run this from the project root folder.

onbreak {resume}
transcript on

file mkdir "sim/baseline/logs"
file mkdir "sim/baseline/waveforms"

transcript file "sim/baseline/logs/tb_mix_columns_one_column_baseline_log.txt"

echo "=============================================="
echo "RUNNING tb_mix_columns_one_column_baseline"
echo "=============================================="

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# Compile all RTL files for this design, then this testbench.
vlog -sv [glob "rtl/baseline/*.sv"]
vlog -sv "tb/baseline/tb_mix_columns_one_column.sv"

# Save waveform database to the correct folder.
vsim -wlf "sim/baseline/waveforms/tb_mix_columns_one_column_baseline.wlf" work.tb_mix_columns_one_column

# Add all testbench and DUT signals into the waveform.
view wave
add wave -r sim:/tb_mix_columns_one_column/*

run -all

# Force waveform/log database to close cleanly before the next test.
quit -sim
transcript file ""

echo "=============================================="
echo "FINISHED tb_mix_columns_one_column_baseline"
echo "Log      : sim/baseline/logs/tb_mix_columns_one_column_baseline_log.txt"
echo "Waveform : sim/baseline/waveforms/tb_mix_columns_one_column_baseline.wlf"
echo "=============================================="
