.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:

li x1,1
li x2,2

beq x1, x2, equal #no branch
add x1,x1,x2
add x1,x1,x2
add x1,x1,x2
bne x1,x2, not_equal #branch
nop
add x1,x1,x1
nop

equal:
nop
not_equal:

beq x1, x2, equal

li x1,1
li x2,2
li x3,1

bge x2, x1,bge_t
li x4,5
bge_t:
bge x1, x2,bge_f
li x4,6
bge_f:

bgeu x2, x1,bgeu_t
li x4,5
bgeu_t:
bgeu x1, x2,bgeu_f
li x4,6
bgeu_f:

blt x2, x1,blt_t
li x4,5
blt_t:
blt x1, x2,blt_f
li x4,6
blt_f:

blt x2, x1,bltu_t
li x4,5
bltu_t:
blt x1, x2,bltu_f
li x4,6
bltu_f:

slti x0, x0, -256
