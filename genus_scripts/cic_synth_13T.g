if {[file exists fv/]} {
    echo "Deleting fv..."
    file delete -force fv/
}

if {[file exists *.cmd]} {
    echo "Deleting cmd..."
    file delete -force *.cmd*
}

if {[file exists *.log]} {
    echo "Deleting log..."
    file delete -force *.log*
}

if {[file exists .goutputstream*]} {
    echo "Deleting goutputstream..."
    file delete -force .goutputstream*
}

if {[file exists *.tstamp]} {
    echo "Deleting tstamp..."
    file delete -force *.tstamp
}

set_db information_level 9 
set_db hdl_error_on_blackbox true 


set_db init_hdl_search_path {./hdl/} 
set_db init_lib_search_path {/eda/DK/TPSC065/PDK4.8/TPS65ISC_STDCELL_LIB/SLVT_LIB/ccs_libs} 
set_db library sc_SLVT_MAX.lib


read_hdl -language vhdl cic_top_v3.vhd counter.vhd integrator.vhd differentiator.vhd
elaborate cic_top_v3

read_sdc ./constraints/timing.sdc

syn_generic
syn_map
syn_opt

report_timing -lint

report_timing > outputs/synth_report_timing_13t_slvt.txt
report_gates > outputs/synth_report_gates_13t_slvt.txt
report_power > outputs/synth_report_power_13t_slvt.txt

write_hdl > outputs/cic_netlist_13t_slvt.v
write_sdc > outputs/contrainst_out.sdc

