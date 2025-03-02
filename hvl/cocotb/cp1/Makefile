TOPLEVEL_LANG ?= verilog

PWD=$(shell pwd)

VERILOG_SOURCES = $(PWD)/../hdl/cpu.sv

TOPLEVEL := cpu
MODULE   := test_fetch

include $(shell cocotb-config --makefiles)/Makefile.sim
