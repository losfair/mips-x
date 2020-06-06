# mips-x

Another MIPS32 CPU.

This is my course design for Computer Organization @ NUAA, 2020 Spring.

## Features

- 45 instructions
- 5-stage single-issue, in-order pipeline
- Microcoded instruction decoder
- Static branch prediction
- Partial bypassing (ALU->ALU). 3 cycles per load/store.
- Runs at 110 MHz on a Xilinx Artix-7 and 50 MHz on a Cyclone IV board.

## License

All rights reserved before July 15, 2020. Open sourced for educational purpose only.

Automatically relicensed under the MIT license after July 15, 2020.
