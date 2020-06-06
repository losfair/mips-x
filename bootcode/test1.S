.section .text
.set noreorder

addi $a0, 1
sw $a0, 0($sp)
addi $a1, 2
sw $a1, 4($sp)

beq $zero, $zero, label1
lw $t1, 0($sp)
addi $zero, $zero, 0
addi $zero, $zero, 0
nop
nop

label1:
syscall