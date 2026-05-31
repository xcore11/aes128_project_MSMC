# Auto-generated ModelSim script for tb_mix_columns (baseline)
# Run this script from the project root folder.
#
# This script:
#   1. Compiles RTL and testbench
#   2. Saves one waveform file
#   3. Saves one cleaned log file containing only testbench $display output

onbreak {resume}

set PROJECT_ROOT [pwd]
cd "sim/baseline"

file mkdir "logs"
file mkdir "waveforms"
if {![file exists "work"]} {
    vlib "work"
}
vmap work "work"

# Make AES test vector path work for tb_aes128_encrypt if needed.
if {![file exists "../../tb/test_vectors.txt"] && [file exists "../../test_vectors.txt"]} {
    file copy -force "../../test_vectors.txt" "../../tb/test_vectors.txt"
}

echo "=============================================="
echo "RUNNING tb_mix_columns (baseline)"
echo "Working directory: [pwd]"
echo "=============================================="

set rtl_files [lsort [glob -nocomplain "../../rtl/baseline/*.sv"]]
if {[llength $rtl_files] == 0} {
    echo "ERROR: No RTL files found in ../../rtl/baseline"
    cd $PROJECT_ROOT
    return
}

foreach rtl_file $rtl_files {
    vlog -sv "$rtl_file"
}

set tb_file "../../tb/baseline/tb_mix_columns.sv"
if {![file exists $tb_file]} {
    echo "ERROR: Testbench file not found: $tb_file"
    cd $PROJECT_ROOT
    return
}

vlog -sv "$tb_file"

vsim -wlf "waveforms/tb_mix_columns.wlf" work.tb_mix_columns

view wave
add wave -divider "tb_mix_columns"
add wave -r sim:/tb_mix_columns/*

# Start transcript only for the simulation run.
# The log is then filtered in-place to remove ModelSim command/noise lines.
set log_file "logs/tb_mix_columns_log.txt"
transcript file $log_file

run -all

# Redirect transcript away from the final log before cleaning.
# This prevents ModelSim control lines and the next script from being appended
# to this testbench log file.
transcript file "work/_discard_transcript.txt"

# Clean the transcript IN PLACE.
# Keeps only the block from the testbench "Started" line to the final "RESULT:" line.
if {[file exists $log_file]} {
    set f [open $log_file r]
    set text [read $f]
    close $f

    set lines [split $text "\n"]
    set clean_lines {}
    set started 0
    set done 0
    set previous ""

    foreach line $lines {
        if {$done} {
            break
        }

        if {!$started} {
            if {([string first "Test Started" $line] >= 0) || ([string first "TESTBENCH STARTED" $line] >= 0) || ([string first "Testbench Started" $line] >= 0)} {
                set started 1

                # Keep the separator immediately before the title if present.
                if {[string first "====" $previous] >= 0} {
                    lappend clean_lines $previous
                }

                lappend clean_lines $line
            }
        } else {
            # Skip simulator/control lines that may still appear during $stop/$finish handling.
            if {[string first "# ** Note:" $line] == 0} {
                continue
            }
            if {[string first "#    Time:" $line] == 0} {
                continue
            }
            if {[string first "# Break in Module" $line] == 0} {
                continue
            }
            if {[string first "# transcript off" $line] == 0} {
                continue
            }
            if {[string first "# End time:" $line] == 0} {
                continue
            }
            if {[string first "# Errors:" $line] == 0} {
                continue
            }
            if {[string first "# Warnings:" $line] == 0} {
                continue
            }

            lappend clean_lines $line

            if {[string first "RESULT:" $line] >= 0} {
                set done 1
            }
        }

        set previous $line
    }

    set f [open $log_file w]
    foreach line $clean_lines {
        puts $f $line
    }
    close $f
}

quit -sim

cd $PROJECT_ROOT
