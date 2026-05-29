transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/sub_bytes.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/shift_rows.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/sbox.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/mix_columns.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/key_expansion.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/aes128_baseline.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/aes_round.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/aes_core.sv}
vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/rtl/baseline/add_roundkey.sv}

vlog -sv -work work +incdir+C:/Users/chinw/OneDrive\ -\ moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/quartus/baseline/../../tb/Baseline {C:/Users/chinw/OneDrive - moe-dl.edu.my/Documents/GitHub/ECE4063_GIthub/aes128_project_G/quartus/baseline/../../tb/Baseline/tb_aes128_encrypt.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -voptargs="+acc"  tb_aes128_encrypt

add wave *
view structure
view signals
run -all
