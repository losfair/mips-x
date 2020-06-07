all:
	mipsel-linux-gnu-gcc -ffreestanding -nostdlib -c -o boot.o boot.S
	mipsel-linux-gnu-ld -T linker.ld -o code.elf boot.o
	mipsel-linux-gnu-objcopy -O binary code.elf code.bin
	python3 hexencode.py < code.bin > ../code.txt
	mipsel-linux-gnu-objdump -D code.elf > code.dump
