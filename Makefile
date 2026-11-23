SRC = rtl/vga_sync.v rtl/pattern_gen.v
TB  = tb/tb_vga.v

.PHONY: sim wave clean

sim:
	iverilog -g2012 -Wall -o tb_vga.vvp $(TB) $(SRC)
	vvp tb_vga.vvp

wave: sim
	gtkwave tb_vga.vcd

clean:
	rm -f *.vvp *.vcd
