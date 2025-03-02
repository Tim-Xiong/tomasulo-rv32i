# defaults
SIM ?= vcs
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../../hdl/shift_add_multiplier.sv

COMPILE_ARGS = -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/1ns -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = shift_add_multiplier

# MODULE is the basename of the Python test file
MODULE = test_sam

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# .PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && $(VERDI_HOME)/bin/verdi -ssf $(PWD)/dump.fsdb

.PHONY: clean
clean::
	rm -rf verdi
