# .section .text
# .globl _start
#     # Refer to the RISC-V ISA Spec for the functionality of
#     # the instructions in this test program.
# _start:

# addi x1, x0, 0xFF
# sw x1, 0(x0)
# lw x2, 0(x0)

    .section .data
data_store:
    .word 0x12345678       # Initial data to be loaded into a register and then stored back

    .section .text
    .globl _start
_start:
    # Load the address of data_store into x1
    la x1, data_store

    # Load word from memory into x2
    lw x2, 0(x1)           # x2 should have 0x12345678

    # Store word from x2 to memory at a different location
    sw x2, 4(x1)           # Store word; memory at data_store + 4 should now have 0x12345678

    # Load byte to check for correct storage
    lbu x3, 4(x1)          # Load byte unsigned; x3 should have 0x78 (lowest byte)

    # Load from a new address to check dependency issues
    lw x4, 0(x1)           # x4 should still load 0x12345678, no dependency issue if x4 is correct

    # Storing byte to test store functionality and subsequent load
    li x5, 0xFF            # Load immediate value 0xFF into x5
    sb x5, 6(x1)           # Store lowest byte of x5 into memory, affecting only one byte

    # Load the modified memory back to check correct byte store
    lbu x6, 6(x1)          # x6 should now be 0xFF
    
    # li x5, 0xFF
    # sb x5, 8(x1)
    # lbu x6, 8(x1)

    # Test for use-after-write dependency
    addi x7, x2, 1         # x7 = x2 + 1; dependency on x2 being loaded correctly
    sw x7, 8(x1)           # Store the result in memory

    # Final load to confirm all operations
    lw x8, 8(x1)           # Load to check if the addition and store were successful (x8 should be 0x12345679)

    # End of test
slti x0, x0, -256
