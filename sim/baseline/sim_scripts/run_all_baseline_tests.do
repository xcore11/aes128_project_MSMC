# Auto-generated master script for all baseline testbenches
onbreak {resume}
echo "=============================================="
echo "RUNNING ALL BASELINE TESTBENCHES"
echo "=============================================="

do "sim/baseline/sim_scripts/run_tb_add_roundkey.do"
do "sim/baseline/sim_scripts/run_tb_sbox.do"
do "sim/baseline/sim_scripts/run_tb_sub_bytes.do"
do "sim/baseline/sim_scripts/run_tb_shift_rows.do"
do "sim/baseline/sim_scripts/run_tb_mix_columns.do"
do "sim/baseline/sim_scripts/run_tb_mix_columns_one_column.do"
do "sim/baseline/sim_scripts/run_tb_key_expansion.do"
do "sim/baseline/sim_scripts/run_tb_aes_round_stage.do"
do "sim/baseline/sim_scripts/run_tb_aes128_encrypt.do"

echo "=============================================="
echo "ALL BASELINE TESTBENCHES FINISHED"
echo "Logs:      sim/baseline/logs"
echo "Waveforms: sim/baseline/waveforms"
echo "=============================================="
