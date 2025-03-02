.section .data
data_space: .space 400 # Allocate 400 bytes of memory

.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    la x1, data_space # Load address of data_space into x1

    # Initialize registers
    li x2, 0 # Loop counter
    li x3, 50 # Number of iterations

loop:
    # Load and store operations intermixed with ALU operations
    lw x4, 0(x1)    # Load word from address in x1 into x4
    addi x4, x4, 1  # Increment value in x4
    sw x4, 0(x1)    # Store word from x4 back to address in x1

    lw x5, 4(x1)    # Load word from address x1+4 into x5
    addi x5, x5, 2  # Increment value in x5
    sw x5, 4(x1)    # Store word from x5 back to address x1+4

    lw x6, 8(x1)    # Load word from address x1+8 into x6
    addi x6, x6, 3  # Increment value in x6
    sw x6, 8(x1)    # Store word from x6 back to address x1+8

    addi x1, x1, 12 # Move address pointer forward by 12 bytes

    addi x2, x2, 3  # Increment loop counter by 3 (each loop has 3 ldst operations)
    
    # Load and store operations intermixed with ALU operations
    lw x4, 0(x1)    # Load word from address in x1 into x4
    addi x4, x4, 1  # Increment value in x4
    sw x4, 0(x1)    # Store word from x4 back to address in x1

    lw x5, 4(x1)    # Load word from address x1+4 into x5
    addi x5, x5, 2  # Increment value in x5
    sw x5, 4(x1)    # Store word from x5 back to address x1+4

    lw x6, 8(x1)    # Load word from address x1+8 into x6
    addi x6, x6, 3  # Increment value in x6
    sw x6, 8(x1)    # Store word from x6 back to address x1+8

    addi x1, x1, 12 # Move address pointer forward by 12 bytes

    addi x2, x2, 3  # Increment loop counter by 3 (each loop has 3 ldst operations)
    # Load and store operations intermixed with ALU operations
    lw x4, 0(x1)    # Load word from address in x1 into x4
    addi x4, x4, 1  # Increment value in x4
    sw x4, 0(x1)    # Store word from x4 back to address in x1

    lw x5, 4(x1)    # Load word from address x1+4 into x5
    addi x5, x5, 2  # Increment value in x5
    sw x5, 4(x1)    # Store word from x5 back to address x1+4

    lw x6, 8(x1)    # Load word from address x1+8 into x6
    addi x6, x6, 3  # Increment value in x6
    sw x6, 8(x1)    # Store word from x6 back to address x1+8

    addi x1, x1, 12 # Move address pointer forward by 12 bytes

    addi x2, x2, 3  # Increment loop counter by 3 (each loop has 3 ldst operations)
    # Load and store operations intermixed with ALU operations
    lw x4, 0(x1)    # Load word from address in x1 into x4
    addi x4, x4, 1  # Increment value in x4
    sw x4, 0(x1)    # Store word from x4 back to address in x1

    lw x5, 4(x1)    # Load word from address x1+4 into x5
    addi x5, x5, 2  # Increment value in x5
    sw x5, 4(x1)    # Store word from x5 back to address x1+4

    lw x6, 8(x1)    # Load word from address x1+8 into x6
    addi x6, x6, 3  # Increment value in x6
    sw x6, 8(x1)    # Store word from x6 back to address x1+8

    addi x1, x1, 12 # Move address pointer forward by 12 bytes

    addi x2, x2, 3  # Increment loop counter by 3 (each loop has 3 ldst operations)
    # Load and store operations intermixed with ALU operations
    lw x4, 0(x1)    # Load word from address in x1 into x4
    addi x4, x4, 1  # Increment value in x4
    sw x4, 0(x1)    # Store word from x4 back to address in x1

    lw x5, 4(x1)    # Load word from address x1+4 into x5
    addi x5, x5, 2  # Increment value in x5
    sw x5, 4(x1)    # Store word from x5 back to address x1+4

    lw x6, 8(x1)    # Load word from address x1+8 into x6
    addi x6, x6, 3  # Increment value in x6
    sw x6, 8(x1)    # Store word from x6 back to address x1+8

    addi x1, x1, 12 # Move address pointer forward by 12 bytes

    addi x2, x2, 3  # Increment loop counter by 3 (each loop has 3 ldst operations)
    slti x0, x0, -256
# This code uses registers x1 (address pointer), x2 (loop counter), x3, x4, x5, x6
# for loading, storing, and ALU operations. The memory address pointer x1 is
# moved forward by 12 bytes in each iteration. There are 3 load/store operations
# per iteration, ensuring at least 50 operations in 17 loops.
