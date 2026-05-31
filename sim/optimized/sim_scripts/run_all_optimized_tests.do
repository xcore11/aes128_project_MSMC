onbreak {resume}

echo "=============================================="
echo "RUNNING ALL OPTIMIZED TESTBENCHES"
echo "=============================================="

do "sim/optimized/sim_scripts/run_tb_sbox.do"
do "sim/optimized/sim_scripts/run_tb_shift_rows.do"
do "sim/optimized/sim_scripts/run_tb_mix_columns_one_column.do"
do "sim/optimized/sim_scripts/run_tb_aes128_encrypt.do"

echo "=============================================="
echo "ALL OPTIMIZED TESTBENCHES FINISHED"
echo "=============================================="
