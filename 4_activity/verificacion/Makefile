VERILATOR ?= verilator
TB   := tb_uart_tx_ctrl.sv
TOP  := tb_uart_tx_ctrl
MOD  := ../SRC
WARN := -Wall -Wno-fatal -Wno-UNUSEDSIGNAL -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
        -Wno-WIDTHTRUNC -Wno-UNOPTFLAT -Wno-PINCONNECTEMPTY -Wno-BLKSEQ -Wno-MULTIDRIVEN
FLAGS := --binary --timing --assert -j 0 $(WARN) --top-module $(TOP)

.PHONY: all lint sim sim-v sim-simple sim-assert bug trace clean

all: sim sim-v sim-simple sim-assert

lint:
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME $(MOD)/uart_tx_ctrl.sv
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME $(MOD)/uart_tx_simple.sv
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME --assert +define+ASSERTIONS uart_tx_ctrl_assert.sv

sim:
	$(VERILATOR) $(FLAGS) --Mdir obj_sv $(MOD)/uart_tx_ctrl.sv $(TB) -o Vsv
	./obj_sv/Vsv

sim-v:
	$(VERILATOR) $(FLAGS) --Mdir obj_v $(MOD)/uart_tx_ctrl.v $(TB) -o Vv
	./obj_v/Vv

sim-simple:
	$(VERILATOR) $(FLAGS) --Mdir obj_simple $(MOD)/uart_tx_simple.sv $(TB) -o Vsimple
	./obj_simple/Vsimple

sim-assert:
	$(VERILATOR) $(FLAGS) +define+ASSERTIONS --Mdir obj_assert uart_tx_ctrl_assert.sv $(TB) -o Vassert
	./obj_assert/Vassert

bug:
	$(VERILATOR) $(FLAGS) +define+ASSERTIONS +define+BUG_PARITY --Mdir obj_bug uart_tx_ctrl_assert.sv $(TB) -o Vbug
	-./obj_bug/Vbug

trace:
	$(VERILATOR) $(FLAGS) --trace --Mdir obj_trace $(MOD)/uart_tx_ctrl.sv $(TB) -o Vtrace
	./obj_trace/Vtrace +trace

clean:
	rm -rf obj_sv obj_v obj_simple obj_assert obj_bug obj_trace uart_tx.vcd
