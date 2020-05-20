simulate: microcode
	cd rtl && iverilog -o ../mips-x -c list.txt

microcode:
	./mcgen/target/release/mcgen -d ./microcode/signals.yaml -m ./microcode/decode.yaml > ./microcode.hex

clean:
	rm microcode.hex

.PHONY: simulate microcode clean
