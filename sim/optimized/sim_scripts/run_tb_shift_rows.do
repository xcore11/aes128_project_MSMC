# Auto-generated ModelSim script for tb_shift_rows optimized
# Run from project root: Project/
# Creates clean log and waveform without modifying the testbench.

onbreak {resume}
set PROJECT_ROOT [pwd]
cd "sim/optimized"

file mkdir "logs"
file mkdir "waveforms"
file mkdir "work"
file mkdir "work/tmp_logs"

if {![file exists "../../tb/test_vectors.txt"] && [file exists "../../test_vectors.txt"]} {
    file copy -force "../../test_vectors.txt" "../../tb/test_vectors.txt"
}

echo "=============================================="
echo "RUNNING tb_shift_rows (optimized)"
echo "Working directory: [pwd]"
echo "=============================================="

vlib "work"
vmap work "work"

set rtl_files [lsort [glob -nocomplain "../../rtl/optimized/*.sv"]]
if {[llength $rtl_files] == 0} {
    echo "ERROR: No RTL files found in ../../rtl/optimized"
    cd $PROJECT_ROOT
    return
}

foreach rtl_file $rtl_files {
    vlog -sv "$rtl_file"
}

set tb_file "../../tb/optimized/tb_shift_rows.sv"
if {![file exists $tb_file]} {
    echo "ERROR: Testbench file not found: $tb_file"
    cd $PROJECT_ROOT
    return
}

vlog -sv "$tb_file"

vsim -wlf "waveforms/tb_shift_rows.wlf" work.tb_shift_rows
view wave
add wave -divider "tb_shift_rows"
add wave -r sim:/tb_shift_rows/*

set raw_log   "work/tmp_logs/tb_shift_rows_raw_log.txt"
set clean_log "logs/tb_shift_rows_log.txt"

# Start transcript only for simulation output. Compile/setup output is excluded.
transcript file $raw_log
run -all
transcript off

# If the testbench used $finish, simulation may already be closed. If not, close it now.
catch {quit -sim}

# Clean the transcript into the final report log.
# Keep only from the first testbench-start banner to the RESULT line.
if {[file exists $raw_log]} {
    set in_file [open $raw_log r]
    set out_file [open $clean_log w]
    set keep 0

    while {[gets $in_file line] >= 0} {
        if {[string first "Test Started" $line] >= 0 ||
            [string first "Unit Test Started" $line] >= 0 ||
            [string first "Testbench Started" $line] >= 0} {
            set keep 1
        }

        if {$keep == 1} {
            puts $out_file $line
        }

        if {[string first "RESULT:" $line] >= 0} {
            break
        }
    }

    close $in_file
    close $out_file

    catch {file delete -force $raw_log}
} else {
    echo "WARNING: raw log was not created: $raw_log"
}

echo "Clean log saved to: [file normalize $clean_log]"
echo "Waveform saved to: [file normalize waveforms/tb_shift_rows.wlf]"

cd $PROJECT_ROOT
