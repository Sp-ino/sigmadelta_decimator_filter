########################### -- CSDG - ufrc_serialiser ###############################
# Filename    : ufrc_serialiser_pre_syn.sdc
# Description : SDC timing constraints for GSDG Serialiser
# Created     : 08/06/2021 Herman Larsen (HL)
######################################################################################

##################### Base setup, inc. version, design and units:
set sdc_version 2.0
current_design ufrc_serialiser

set_units -capacitance 1000.0fF
set_units -time 1000.0ps

# Define some generic standard values used throughout, specifics are overridden locally when needed.
set clk_uncertainty 0.2
set clk_transition 0.2

set c_gen_min 0.03 ;#generic output load max/min
set c_gen_max 0.2

set tr_tf_gen 0.3 ;# generic transition time
set tr_tf_slow 0.5 ;# transition time for asynchronous control signals

set dly_gen_min 0.2 ;# generic delay for IO
set dly_gen_max 1.2
set dly_asynch_max 2.5 ;# large delay for loosely constraining asynch IO control 

set dly_low_skew_min 1.0 ;# low skew delay for certain IO
set dly_low_skew_max 1.2 

##################### Clocks: Create input clocks (uncertainty is skew + jitter)
create_clock -name "clk_sc_pulse" -add -period 6.4 -waveform {0.0 1.6} [get_ports clk_sc_pulse_i]

# Set generic clock uncertainty
set_clock_uncertainty $clk_uncertainty [get_clocks clk_*]
set_clock_transition  $clk_transition [get_clocks clk_*]

##################### Clocks, generated:
# Main clock, the Encoder Clock generated in the Aurora Encoder Gearbox and used in the majority of the design.
#  Ensures that only fsp_data_gen_0/fsp_data_valid* are constrained to clk_enc - rest tied to different generated clock.
#  Ensures that specific gearbox registers on clk_sc_pulse are not constrained to wrong clock using the "remove_from_collection" on aurora instance.
create_generated_clock -name "gen_clk_enc" -edges {2 4 6} -source [get_ports clk_sc_pulse_i] \
  [ get_pins { \
      control_0/clk_enc_i \
      adc_bits_counter_0/clk_i \
      single_pulse_incr_0/clk_i \
      fsp_data_gen_0/clk_enc_i } ] \
  [ remove_from_collection \
      [ get_leaf_pins aurora_encoder_0/*clk] \
      [ get_leaf_pins { aurora_encoder_0/gearbox/data_o*/clk \
                        aurora_encoder_0/gearbox/count_r*/clk \
                        aurora_encoder_0/gearbox/clk_enc_o*/clk } ] ]
   
# Set generic generated clock uncertainty
set_clock_uncertainty $clk_uncertainty [get_clocks gen_clk* ]
set_clock_transition  $clk_transition [get_clocks gen_clk* ]

# Enable clock gating checks
set_clock_gating_check -setup 0.0   
set_clock_gating_check -setup 0.0 [get_clock gen_clk_enc] 

##################### Generic IO Configurations
# Set max fanout in the design
set_max_fanout 40 ufrc_serialiser

# Set generic output loads
set_load -pin_load -min $c_gen_min [all_outputs] 
set_load -pin_load -max $c_gen_max [all_outputs]

# Set driving cells range for inputs, assuming relatively low drivers # TODO max was 32, set to biggest actual input driver
set_driving_cell -min -lib_cell BUF_X2_18_SVT -pin "Q" [all_inputs]
set_driving_cell -max -lib_cell CLKBUF_X40_18_SVT -pin "Q" [all_inputs]

# Set known driving cells for data / clocks
set_driving_cell -lib_cell AND2_X2_18_SVT -pin "Q" [get_ports { clk_sc_pulse_i }] 
set_driving_cell -lib_cell SDFFQ_X2_18_SVT -pin "Q" [get_ports { cis_data_i* }] 
set_driving_cell -lib_cell BUF_X16_18_SVT -pin "Q" [get_ports { cis_fsp_data_i* }] 

##################### IO Delays, Transitions, Loads, and False Paths
# Constraints for the input data from the CIS. Delays as follows:
# min: set as a worst case instant data change with the clock signal. Allows simulation with ideal model, and deals with unexpected fast performance.
# max: simulated parasitic estimate or extracted in slowest corners, with ~20% safety. Resimulate for current design parasitics.
set_input_delay -min 0 -clock gen_clk_enc [get_ports { cis_data_i* }] 
set_input_delay -max 3.5 -clock gen_clk_enc [get_ports { cis_data_i* }] 
set_max_transition $tr_tf_gen [get_ports { cis_data_i* }]

# Constraints for the input FSP data from the CIS. May or may not be needed based on CIS system behaviour. Define Asynch otherwise.
#set_input_delay -min $dly_gen_min -clock gen_clk_ufrc_data_valid [get_ports { cis_fsp_data_i* }]
#set_input_delay -max $dly_gen_max -clock gen_clk_ufrc_data_valid [get_ports { cis_fsp_data_i* }]
set_false_path -from [get_ports { cis_fsp_data_i* }] -to [all_clocks] -comment "SDC Asynch FSP Data False Path"
set_max_transition $tr_tf_gen [get_ports { cis_fsp_data_i* }] 

# Constraints for the output data towards the analogue 32-1 serialiser
set_output_delay -min $dly_low_skew_min -clock clk_sc_pulse [get_ports { ufrc_data_o* }] 
set_output_delay -max $dly_low_skew_max -clock clk_sc_pulse [get_ports { ufrc_data_o* }] 
# The SDFFR_X1 SI is about 4 fF, plus parasitic routing , potentially  different from generic value:
set_load -pin_load -min 0.02 [get_ports { ufrc_data_o* }]
set_max_transition $tr_tf_gen [get_ports { ufrc_data_o* }] 

# for interface, debug shift-reg and adcs:
set_output_delay -min $dly_low_skew_min -clock gen_clk_enc [get_ports { *sr_clk_o *sr_load_en_o }]
set_output_delay -max $dly_low_skew_max -clock gen_clk_enc [get_ports { *sr_clk_o *sr_load_en_o }]
set_load -pin_load -max [expr 1.5*$c_gen_max] [get_ports { *sr_clk_o *sr_load_en_o }] ;# set higher (N* max) load on these as long lines
set_max_transition $tr_tf_gen [get_ports { *sr_clk_o *sr_load_en_o }]

# Asynchronous Reset  
set_false_path -from [get_ports rst_ni] -to [all_clocks] -comment "SDC Reset False Path"
set_max_transition $tr_tf_slow [get_ports rst_ni] 

# Asynchronous Power  
set_false_path -from [get_ports {VDD* VSS*}]  -to [all_clocks] -comment "SDC Power False Path"
set_max_transition $tr_tf_slow [get_ports {VDD* VSS*}]

# Asynchronous Control, the "rest" of the signals
#  Not including constraints on the following asynchronous signals  WILL genereate a number of non-constrained warnings in the timing lint. As we can't ensure constraints set here are valid in system, should be left unconstrained.
#set_false_path -from [remove_from_collection [all_inputs] [get_ports {cis*_data_i* clk* rst*}] ] -to [all_clocks] -comment "SDC Asynch Control False Path"
set_false_path -from \
  [ get_ports { \
      adc_conv_ready_dbg_i \
      adc_conv_ready_i \
      adc_incr_bits_i \
      adc_sr_clk_dbg_i \
      adc_sr_load_en_dbg_i \
      aurora_channel_up_i \
      aurora_lane_up_i \
      aurora_send_clock_compensation_i \
      aurora_send_fsp_i \
      fsp_incr_counter_i \
      ser_debug_en_i \
      ser_mux_sel_i \
      ser_repeat_start_seq_i \
      ser_send_start_seq_i \
  } ] -to [all_clocks] -comment "SDC Asynch Control False Path"
  
set_max_transition $tr_tf_slow [remove_from_collection [all_inputs] [get_ports {cis*_data_i* clk* rst*}] ]

##################### Optimisation
# Set multicycle paths for the fsp frame counter to aurora encoder, as this only happens at the end of every readout (N bit lanes /64 *  M bits)
# For the minimum case of 128 adcs of 8 bits depth, that's 16 cycles. We use just 4, as this is more than enough for relaxing slack (~200 ps otherwise, which is false..)
# NB: The second set, with -hold, resets the hold requirement to stop P&R calculating hold constraints to wrong edge (moves back to edge 0 rather than N-1)
set n_mult 2
set n_mult_hold [ expr $n_mult - 1 ]
set_multicycle_path $n_mult -from [get_pins fsp_data_gen_0/fsp_frame_counter/count_o*/clk] -to [get_clocks gen_clk_enc]
set_multicycle_path $n_mult -from [get_pins fsp_data_gen_0/fsp_data_r_reg*/clk] -to [get_clocks gen_clk_enc]
set_multicycle_path $n_mult_hold -from [get_pins fsp_data_gen_0/fsp_frame_counter/count_o*/clk] -to [get_clocks gen_clk_enc] -hold
set_multicycle_path $n_mult_hold -from [get_pins fsp_data_gen_0/fsp_data_r_reg*/clk] -to [get_clocks gen_clk_enc] -hold

# Don't analyse paths for ser_debug_en_i = 1 and ser_mux_sel_i = 1, these are debug paths only, not to be optimised
set_case_analysis 0 [get_ports ser_debug_en_i]
set_case_analysis 0 [get_ports ser_mux_sel_i]

