import os
import random
import sys
from pathlib import Path

import cocotb
from cocotb.runner import get_runner
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def sam_basic_test(dut):
    """Test for 5 * 10"""

    a = 214748360
    b = 10

    dut._log.info("Initialize and reset model")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    dut.start.value = 0
    dut.mul_type.value = 0
    dut.data.value = 0
    dut.data.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

    dut._log.info("Test multiplication operations")
    await RisingEdge(dut.clk)
    dut.start.value = 1
    dut.mul_type.value = 1
    dut.data.operation.value = 0
    dut.data.q2_data.value = a
    dut.data.q1_data.value = b
    for _ in range(200):
        await RisingEdge(dut.clk)


# @cocotb.test()
# async def sam_randomised_test(dut):
#     """Test for adding 2 random numbers multiple times"""

#     for i in range(10):

#         A = random.randint(0, 15)
#         B = random.randint(0, 15)

#         dut.a.value = A
#         dut.b.value = B

#         await Timer(2, units="ns")

#         assert dut.X.value == adder_model(
#             A, B
#         ), "Randomised test failed with: {A} + {B} = {X}".format(
#             A=dut.A.value, B=dut.B.value, X=dut.X.value
#         )


def test_adder_runner():
    """Simulate the adder example using the Python runner.

    This file can be run directly or via pytest discovery.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "vcs")

    proj_path = Path(__file__).resolve().parent.parent

    verilog_sources = []
    vhdl_sources = []

    if hdl_toplevel_lang == "verilog":
        verilog_sources = [proj_path / "hdl" / "shift_add_multiplier.sv"]
    else:
        vhdl_sources = [proj_path / "hdl" / "shift_add_multiplier.vhdl"]

    runner = get_runner(sim)
    runner.build(
        verilog_sources=verilog_sources,
        vhdl_sources=vhdl_sources,
        hdl_toplevel="shift_add_multiplier",
        always=True,
    )
    runner.test(hdl_toplevel="shift_add_multiplier", test_module="test_sam")


if __name__ == "__main__":
    test_adder_runner()
