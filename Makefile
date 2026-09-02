# Default target: build the whole scripted Basys3 port tree.
TOOLS        := contrib/tools
BASYS3_TOOLS := contrib/basys3/tools
VIVADO       := contrib/basys3/vivado

.PHONY: all setup create_prj clk_wiz patch synth bitstream clean

all: setup clk_wiz patch

setup:
	$(TOOLS)/setup_arcade_pooyan.sh

create_prj:
	$(VIVADO)/create_project.sh

clk_wiz: setup create_prj
	$(VIVADO)/make_clk_wiz_0.sh

# Regenerate the arcade_pooyan_basys3.vhd top-level wrapper.
patch: setup
	$(BASYS3_TOOLS)/make_de10_lite_to_basys3_wrapper.sh

# Run synthesis only (resets synth_1 first).
synth: setup clk_wiz patch
	$(BASYS3_TOOLS)/make_arcade_pooyan_basys3_bitstream.sh synth

# Implementation + write_bitstream (depends on synthesis).
bitstream: synth
	$(BASYS3_TOOLS)/make_arcade_pooyan_basys3_bitstream.sh bitstream

# Remove the Vivado project/build tree only — the upstream sources are checked
# in and must never be deleted.
clean:
	rm -rf basys3
