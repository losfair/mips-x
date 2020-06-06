.section .text

addi $a0, $zero, 99
addi $a1, $zero, 2
mult $a0, $a1
mflo $a0
mfhi $a1

addi $t0, $zero, 99
addi $t1, $zero, 2
mtlo $t0
mthi $t1
mflo $a0
mfhi $a1
nop
syscall