simulate: microcode
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
	mipsel-linux-gnu-gcc -ffreestanding -nostdlib -c -o ./bootcode/boot.o ./bootcode/boot.S
	mipsel-linux-gnu-ld -T ./scripts/linker.ld -o code.elf ./bootcode/boot.o
	mipsel-linux-gnu-objcopy -O binary code.elf code.bin
	python3 ./scripts/hexencode.py < code.bin > code.txt

clean:
	rm microcode_control.hex microcode_alufunc.hex

.PHONY: simulate microcode bootcode clean
