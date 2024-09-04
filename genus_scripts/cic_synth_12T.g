# --------------------- Parameters -------------------
set LIBRARY "ccs_sc_12T_SLVT_MAX.lib"
set LIB_PATH "/eda/DK/TPSC065/PDK4.8/TPS65ISC_STD_LIB/12T_SLVT_LIB/ccs"

# Possible search paths:
# hdl/basic_noadder -> basic cic without custom adder
# hdl/basic -> basic cic with custom adder
# hdl/factorized -> nonrecursive cic with factorization
# hdl/factorized_increm -> nonrecursive cic with factorization and optimized adder word length
set HDL_PATH "./hdl/basic"
set TOP_MODULE CIC




# ----- Pass parameters and input files to Genus -----
set_db information_level 9 
set_db hdl_error_on_blackbox true

set_db init_lib_search_path $LIB_PATH
set_db library $LIBRARY
set_db init_hdl_search_path $HDL_PATH

# Use this when HDL_PATH is hdl/basic_noadder
# read_hdl -language vhdl cic_top_v3.vhd counter.vhd integrator.vhd differentiator.vhd

# Use this when HDL_PATH is hdl/basic
read_hdl -language vhdl cic.vhdl comb.vhdl integrator.vhdl adder.vhdl

# Use this when HDL_PATH is none of the above (i.e. not basic_noadder nor 
# read_hdl -language vhdl cic.vhdl chain.vhdl ripple_carry_adder.vhdl tf.vhdl



# --------------------- Run synthesis -----------------
elaborate $TOP_MODULE
read_sdc ./constraints/timing.sdc

syn_generic
syn_map
syn_opt




# --------- Generate outputs and write to file --------
report_timing -lint

report_timing > outputs/synth_report_timing_12t_slvt.txt
report_gates > outputs/synth_report_gates_12t_slvt.txt
report_power > outputs/synth_report_power_12t_slvt.txt

write_hdl > outputs/cic_netlist_12t_slvt.v
write_sdc > outputs/contrainst_out.sdc


