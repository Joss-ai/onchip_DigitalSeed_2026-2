###############################################################################
# Created by write_sdc
###############################################################################
current_design Encoder
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 10.0000 [get_ports {clk}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_propagated_clock [get_clocks {clk}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[0]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[1]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[2]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[3]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[4]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[5]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Comp[6]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Samp}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Dout[0]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Dout[1]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {Dout[2]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {eoc}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0334 [get_ports {eoc}]
set_load -pin_load 0.0334 [get_ports {Dout[2]}]
set_load -pin_load 0.0334 [get_ports {Dout[1]}]
set_load -pin_load 0.0334 [get_ports {Dout[0]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Samp}]
set_driving_cell -lib_cell sky130_fd_sc_hd__clkinv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[6]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[5]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[4]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[3]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[2]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[1]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {Comp[0]}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 0.7500 [current_design]
set_max_capacitance 0.2000 [current_design]
set_max_fanout 10.0000 [current_design]
