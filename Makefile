simulate: simulate-no-bootcode bootcode

simulate-no-bootcode: microcode
	cd rtl && iverilog -o ../mips-x -c list.txt

synthesis:
	yosys synthesis.ys

pnr:
	nextpnr-ice40 --up5k --json mips-x.json --asc mips-x-ice40-up5k.asc --freq 12

microcode:
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode_control.yaml > ./microcode_control.hex
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode_alufunc.yaml > ./microcode_alufunc.hex
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode_regimm.yaml > ./microcode_regimm.hex

bootcode:
	make -C bootcode

clean:
	rm microcode_control.hex microcode_alufunc.hex

.PHONY: simulate-no-bootcode microcode bootcode clean
