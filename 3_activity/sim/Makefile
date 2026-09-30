######################################################################
# Verilator Makefile - Proyecto fifo sync
######################################################################

# Verilator
VERILATOR ?= verilator

# Top module (tu testbench)
TOP = tb

# Archivos fuente

PKGS = \
	Transobject.sv \
	gen.sv \
	interfaz.sv \
	driver.sv \
	Monitor.sv \
	scoreboard.sv \
	Enviroment.sv \
	test.sv 

RTL = FIFO.v

TB = \
    tb.sv

SRCS = $(PKGS) $(RTL) $(TB)


# Flags
VERILATOR_FLAGS = --binary --sv -j 0 -Wall \
                  --top-module $(TOP) \
                  -Wno-DECLFILENAME -Wno-EOFNEWLINE \
                  --trace

VERILATOR_FLAGS += --timing

ifeq ($(ignore),1)
    VERILATOR_FLAGS += -Wno-fatal
endif

ifeq ($(trace),1)
	VERILATOR_FLAGS +=  --trace
endif

######################################################################

.PHONY: all build run clean

# Default
all: build run

######################################################################
# Build
######################################################################

build:
	@echo "-- VERILATING & BUILDING --"
	$(VERILATOR) $(VERILATOR_FLAGS) $(SRCS)

######################################################################
# Run
######################################################################

run:
	@echo "-- RUNNING SIMULATION --"
	obj_dir/V$(TOP)

	@if [ "$(trace)" = "1" ]; then \
		echo "-- OPENING GTKWave --"; \
		gtkwave dump.vcd; \
	fi

######################################################################
# Clean
######################################################################

clean:
	@echo "-- CLEAN --"
	rm -rf obj_dir *.log *.vcd

######################################################################