.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.

_start:

jal x0,st

func_1:
addi x2,x2,1
bne x2,x3,func_1
jalr x0,0(x10)

st:
li x1,100
li x2,200

jal x1,jal_target_1
nop
nop
nop
jal_target_2:
nop
nop
nop
jal x0,jal_target_3
nop

jal_target_1:
li x3,300
jal x2,jal_target_2

jal_target_3:

li x2,0
li x3,5
jal x1, jalr_target
nop

slti x0, x0, -256


jalr_target:
add x2,x2,x3
li x2,1
li x3,10
jal x10,func_1
add x2,x2,x3
jalr x10,0(x1)
