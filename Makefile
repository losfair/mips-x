simulate: microcode
	cd rtl && iverilog -o ../mips-x -c list.txt

microcode:
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode_control.yaml > ./microcode_control.hex
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode_alufunc.yaml > ./microcode_alufunc.hex
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode_regimm.yaml > ./microcode_regimm.hex

clean:
	rm microcode_control.hex microcode_alufunc.hex

.PHONY: simulate microcode clean
