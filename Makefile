# === Reusable Makefile with rtl/ and tb/ directories ===

# Default testbench file (override with TB=tb_xxx.sv)
TB     ?= $(shell ls tb/tb_*.sv | head -n1)
TOP    := $(basename $(notdir $(TB)))   # e.g. tb_dtm_jtag_tap

# RTL and TB source files
RTL_SRCS := $(wildcard rtl/*.sv)
TB_SRCS  := $(wildcard tb/*.sv)

# All sources to compile
SRCS := $(RTL_SRCS) $(TB)

# Output files
OUT  := simv
WAVE := wave.vcd

# === Compile ===
all: $(OUT)

$(OUT): $(SRCS)
	@echo "Compiling $(TOP)..."
	iverilog -g2012 -o $(OUT) -s $(TOP) $(SRCS)

# === Run simulation ===
run: $(OUT)
	@echo "Running simulation..."
	vvp $(OUT)

# === View waveform ===
wave: $(WAVE)
	@echo "👁️  Opening GTKWave..."
	gtkwave $(WAVE)

# === All in one ===
sim: all run wave

# === Clean up ===
clean:
	@echo "Cleaning..."
	rm -f $(OUT) $(WAVE)
