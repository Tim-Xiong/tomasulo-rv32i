
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:

li x1,1
li x2,2
mul x3,x1,x2
mul x3,x1,x2
mul x3,x1,x2
mul x3,x1,x2
mul x3,x1,x2
mul x3,x1,x2
addi x1, x0, 1        # x1 = 1, Initialize x1 with 1
addi x2, x0, 2        # x2 = 2, Initialize x2 with 2
add  x3, x1, x2       # x3 = 3, Addition, dependent on x1 and x2
sub  x4, x3, x1       # x4 = 2, Subtraction, dependent on x3 and x1
sll  x5, x4, x1       # x5 = 4, Shift left logical, dependent on x4 and x1
xor  x6, x5, x3       # x6 = 7, XOR, dependent on x5 and x3# 
or   x7, x6, x2       # x7 = 7, OR, dependent on x6 and x2
and  x8, x7, x5       # x8 = 4, AND, dependent on x7 and x5
slt  x9, x8, x7       # x9 = 1 if x8 < x7, SLT, sets x9 based on comparison of x8 and x7
srl  x10, x8, x2      # x10 = 1, Shift right logical, dependent on x8 and x2
sra  x11, x10, x1     # x11 = 0, Shift right arithmetic, dependent on x10 and x1
add  x12, x11, x7     # x12 = 7, Addition, dependent on x11 and x7
xor  x13, x12, x9     # x13 = 6, XOR, dependent on x12 and x9
or   x14, x13, x10    # x14 = 7, OR, dependent on x13 and x10
and  x15, x14, x12    # x15 = 7, AND, dependent on x14 and x12
sub  x16, x15, x13    # x16 = 1, Subtraction, dependent on x15 and x13
add  x17, x16, x16    # x17 = 2, Addition, dependent on x16
sll  x18, x17, x16    # x18 = 4, Shift left logical, dependent on x17 and x16
slt  x19, x18, x17    # x19 = 0, SLT, sets x19 based on comparison of x18 and x17
srl  x20, x19, x18    # x20 = 0, Shift right logical, dependent on x19 and x18
xor  x21, x20, x17    # x21 = 2, XOR, dependent on x20 and x17
or   x22, x21, x18    # x22 = 6, OR, dependent on x21 and x18
and  x23, x22, x19    # x23 = 0, AND, dependent on x22 and x19
add  x24, x23, x22    # x24 = 6, Addition, dependent on x23 and x22
sub  x25, x24, x21    # x25 = 4, Subtraction, dependent on x24 and x21
sll  x26, x25, x24    # x26 = Huge number, Shift left logical, dependent on x25 and x24
xor  x27, x26, x25    # x27 = Result, XOR, dependent on x26 and x25
or   x28, x27, x26    # x28 = Result, OR, dependent on x27 and x26
and  x29, x28, x27    # x29 = Result, AND, dependent on x28 and x27
add  x30, x29, x28    # x30 = Result, Addition, dependent on x29 and x28
sub  x31, x30, x29    # x31 = Result, Subtraction, dependent on x30 and x29

slti x0, x0, -256
