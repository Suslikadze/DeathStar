transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -2008 -work work {C:/projects/SHT/SHT V4.vhd}
vcom -2008 -work work {C:/Users/Ruslan/Desktop/count_n_modul.vhd}

vcom -2008 -work work {C:/projects/SHT/simulation/modelsim/SHT.vht}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneive -L rtl_work -L work -voptargs="+acc"  SHT_vhd_tst

do C:/projects/SHT/wave.do
