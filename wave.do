
_add_menu main controls right SystemButtonFace black RUN_1uS   {run 1000000}
_add_menu main controls right SystemButtonFace blue RUN_10uS   {run 10000000}
_add_menu main controls right SystemButtonFace red  RUN_100uS  {run 100000000}
_add_menu main controls right SystemButtonFace green RUN_1mS   {run 1000000000}
_add_menu main controls right SystemButtonFace magenta  RUN_10mS   {run 10000000000}
_add_menu main controls right SystemButtonFace yellow  RUN_100mS   {run 100000000000}


add wave -noupdate -divider MAIN_INOUT
add wave -position 1  sim:/sht_vhd_tst/i1/SDA
add wave -position 2  sim:/sht_vhd_tst/i1/SCK
add wave -position 3  sim:/sht_vhd_tst/i1/sclk
add wave -position 4  sim:/sht_vhd_tst/i1/rst
add wave -position 5  sim:/sht_vhd_tst/i1/en

add wave -noupdate -divider Clock
add wave -position end  sim:/sht_vhd_tst/i1/aux_clk
add wave -position end  sim:/sht_vhd_tst/i1/data_clk
add wave -position end  sim:/sht_vhd_tst/i1/bus_clk

add wave -noupdate -divider Signals
add wave -position end  sim:/sht_vhd_tst/i1/idle_event
add wave -position end  sim:/sht_vhd_tst/i1/data(0)
add wave -position end  sim:/sht_vhd_tst/i1/i


add wave -noupdate -divider STATE
add wave -position end  sim:/sht_vhd_tst/i1/pr_state


