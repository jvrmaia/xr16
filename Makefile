all:
	ghdl -a xr16.vhd tb_xr16.vhd
	ghdl -e tb_xr16
	ghdl -r tb_xr16

clean:
	ghdl --clean

gtkwave:
	ghdl -r tb_xr16 --vcd=saida.vcd
	gtkwave saida.vcd
