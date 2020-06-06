.section .text
.set reorder

addi $sp, $zero, 0x600

addi $sp, $sp, -16

addi $a0, $zero, 91
sw $a0, 0($sp)
addi $a0, $zero, 33
sw $a0, 4($sp)
addi $a0, $zero, 37
sw $a0, 8($sp)
addi $a0, $zero, 122
sw $a0, 12($sp)

move $a0, $sp
addi $a1, $zero, 0
addi $a2, $zero, 3
jal quickSort

lw $a0, 0($sp)
lw $a1, 4($sp)
lw $a2, 8($sp)
lw $a3, 12($sp)
syscall

swap:
	.set	noreorder
	.set	nomacro
	lw	$2,0($4)
	lw	$3,0($5)
	sw	$3,0($4)
	jr	$31
	sw	$2,0($5)

partition:
	.set	noreorder
	.set	nomacro
	sll	$8,$6,2
	slt	$6,$5,$6
	addu	$8,$4,$8
	addiu	$10,$5,-1
	beq	$6,$0,$L7
	lw	$11,0($8)

	sll	$6,$5,2
	addu	$6,$4,$6
$L6:
	lw	$7,0($6)
	sll	$3,$5,2
	addiu	$12,$10,2
	addu	$3,$4,$3
	slt	$9,$7,$11
	beq	$9,$0,$L5
	move	$2,$5

	lw	$9,0($3)
	move	$10,$5
	addiu	$5,$5,1
	sw	$7,0($3)
	move	$2,$12
	sw	$9,0($6)
$L5:
	addiu	$6,$6,4
	bne	$8,$6,$L6
	nop

	sll	$5,$5,2
	lw	$11,0($8)
	addu	$5,$4,$5
	lw	$3,0($5)
	sw	$11,0($5)
	jr	$31
	sw	$3,0($8)

$L7:
	move	$2,$5
	sll	$5,$5,2
	addu	$5,$4,$5
	lw	$3,0($5)
	sw	$11,0($5)
	jr	$31
	sw	$3,0($8)

quickSort:
	.set	noreorder
	.set	nomacro
	slt	$2,$5,$6
	beq	$2,$0,$L18
	nop

	addiu	$sp,$sp,-40
	sw	$18,32($sp)
	move	$18,$4
	sw	$17,28($sp)
	move	$17,$6
	sw	$16,24($sp)
	move	$16,$5
	sw	$31,36($sp)
	move	$5,$16
$L17:
	move	$6,$17
	jal	partition
	move	$4,$18

	move	$5,$16
	addiu	$6,$2,-1
	jal	quickSort
	addiu	$16,$2,1

	slt	$2,$16,$17
	bne	$2,$0,$L17
	move	$5,$16

	lw	$31,36($sp)
	lw	$18,32($sp)
	lw	$17,28($sp)
	lw	$16,24($sp)
	jr	$31
	addiu	$sp,$sp,40

$L18:
	jr	$31
	nop
