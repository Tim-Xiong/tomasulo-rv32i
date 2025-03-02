.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:

lui x1, 2
auipc x2, 0x3

slti x0, x0, -256
