########################### -- Genus Synthesis Script -- ############################
# Filename    : synth_ufrc_serialiser.tcl
# Description : Synthesis script for Genus in Legacy Mode
#  Run this file from within Genus (launch genus first with: genus -legacy_ui) (preferred):
#   source /path/to/synth_ufrc_serialiser.tcl
#  or by running directly:  (can also be run with -batch)
#   genus -legacy_ui -f /path/to/synth_ufrc_serialiser.tcl
#
#  To stop the script prematurely during testing, use the following statement at the desired place (exluding the preceding #):
#   puts "\[$thisf\] WARNING: Exiting script early due to early return statement"; return;
#
# Version History:
# Created     : 31/01/2018 David Rivas Marchena (DRM)
# Edited      : 17/10/2018 Deividas Krukauskas (DK)     - Edited to synthesise UFRC digital block
# USED        : 05/01/2021 Seddik Benhammadi (BH)       - Used to synthesise C100 Serialiser
# USED        : 24/08/2021 Deividas Krukauskas (DK)     - Used to synthesise C100 ADC
# Edited      : 08/06/2022 Herman Larsen (HL)           - Edited to simplify modifications by using path variables and hdl lists
#
# Usage:
#  Modify the initial part of the script, including 
#   path_project - the path to the git repository - if repo structure is left untouched, should be the only path necessary to change
#   hdl_list - ensure all HDL files needed for synthesis are included. Currently only supports files in one directory.
#   other scipt control mechanisms.
######################################################################################
puts "Executing [info script] ... "
set thisf [file tail [info script] ] 

## Script control
set suspendScript 0     ;# 1 -> suspend script until keypress
set stageDelayMs  2000     ;# suspend script for # ms for readability, set to 0 for fastest runtime
set apply_dft_sdc_constraints  1   ;#

# Path control Inputs
set path_project "/COMMprojects/NOOR/designLib/csdg_serialiser_git" ;# base path of the project to build the other paths from 
set path_hdl [ join [list $path_project "/source_code/design"] "" ] ;# path to the hdl directory
set path_constraint_file [ join [list $path_project "/source_code/constraints/ufrc_serialiser_pre_syn.sdc"] "" ] ;# path to the constraints file
set path_scripts [ join [list $path_project "/implementation_scripts/genus"] "" ] ;# path to directory of this script and setup_libs_genus.tcl

# Cell Top Level and 
set top_cell_name ufrc_serialiser
# HDL Files to Read
set hdl_list ""
lappend hdl_list ufrc_aurora_64b66b_pkg.sv ufrc_gearbox_66to32.v ufrc_channel_control.sv ufrc_scrambler.v ufrc_aurora_encoder_64b66b.v
lappend hdl_list ufrc_serialiser_pkg.sv ufrc_serialiser_parameters_defs.svh ufrc_serialiser_parameters.svh  ufrc_control.sv \
                  ufrc_fsp_data_gen.sv counter_param.sv single_pulse_gen.v ufrc_serialiser.sv

## Genus control
set_attribute max_cpus_per_server 4           ;# Multi-Thread setup for faster runtimes
set_attribute hdl_error_on_blackbox true      ;# Flag errors for blackboxes (missing pieces of design)
set_attribute hdl_error_on_latch true         ;# Flag errors for latches
set_attribute hdl_track_filename_row_col true  ;# Track line numbers on inference, DFT and power reports (increases runtime)
set_attribute hdl_zero_replicate_is_null true ;# Ensure that parametric expressions behave correctly if replication constant becomes 0

## Genus Debug Control, comment out when not in use
#set_attribute ungroup_ok false [find / -instance inst_name] ;# stop ungrouping of specific instances.
#set_attribute auto_ungroup none ;# both/ none - none allows easy debugging but reduces possible optimsation due to no ungrouping. Use for debugging purposes, but better turned off for final P&R

###############################################################################
# Begin setup & read target libraries
# OR remove VIRTUAL genus session designs to allow rerunning the script
###############################################################################
if {[get_attr library /] eq ""} {   
    puts "\[$thisf\] INFO: Setting up Genus session"
    source $path_scripts/libs_setup_genus.tcl ;# Load Liberty timing models  (setup_libs_genus.tcl file assumed to be in same 
} else {
    set currentDesigns [find . -design *]
    if {$currentDesigns ne ""} {
	      puts "\[$thisf\] INFO: Removing virtual designs \"$currentDesigns\""
	      rm /designs/*
    }
}

#Path Control Outputs
set ptime [clock format [clock seconds] -format "%y%m%d_%H%M"] ;# sets the time as YYMMDD_HH:MM_SS
set plib [string range $timing_lib [expr {[string first "_" $timing_lib] + 1}] [expr {[string first "_" $timing_lib] + 2}] ] ;# gets the corner used, relies on setup_libs_genus.tcl having been loaded and the library being in a certain format.
set path_output [ join [list $path_scripts "/genus_${plib}"  ] "" ] ;# can be suffixed with time to not overwirte: _${ptime}
set out_prefix "genus_" ;# output directory prefix, set to "" to have no suffix
set out_suffix "" ;# output directory suffix, set to "" to have no suffix
set path_report_dir $path_output/${out_prefix}reports${out_suffix}
set path_saved_dir $path_output/${out_prefix}saved${out_suffix}
set path_snapshot_dir $path_output/${out_prefix}snapshots${out_suffix}
set path_export_dir $path_output/${out_prefix}export${out_suffix}
set path_lec_dir $path_output/${out_prefix}LEC${out_suffix}

###############################################################################
# Read HDL files and elaborate design
###############################################################################
puts "\[$thisf\] INFO: Reading HDL files and elaborating $top_cell_name"
after $stageDelayMs  ;# Delay for readability

# Read the HDL:
foreach hdl_file $hdl_list {
    puts "  reading $hdl_file"
    read_hdl -sv  $path_hdl/$hdl_file
}

set_attribute information_level 9
elaborate $top_cell_name
set_attribute information_level 1

check_design -unresolved  ;# Check design after read for unresolved instances

# Additional reports that can be printed during developement
#  report sequential -hier
#  report datapath -all
#  check_design -all

###############################################################################
# Set timing and design constraints
###############################################################################
puts "\[$thisf\] INFO: Reading SDC constraints"
after $stageDelayMs  ;# Delay for readability

# Copy the pre_syn constraints into export so we know exactly what was used when ran
cp -f $path_constraint_file $path_export_dir

read_sdc $path_constraint_file
report timing -lint -verbose ;# will be written to file later on: > $path_report_dir/${top_cell_name}_TimingLint_Verbose.rpt

# Enable generating SDC constraints for DFT logic
set_attribute dft_apply_sdc_constraints [string is true $apply_dft_sdc_constraints]

#puts "\[$thisf\] WARNING: Exiting script early due to early return statement"; return;
###############################################################################
# Synthesize the design
###############################################################################
puts "\[$thisf\] INFO: Synthesizing the design"
after $stageDelayMs  ;# Delay for readability

# Synthesize - verbosity >=2 to see deleted instances
set_attribute information_level 9
set_attribute truncate false /messages/GLO/GLO-34  ;# ensures messages about removed instances are printed
# Effort = {low | medium (default) | high | express}
set_attr syn_generic_effort high
syn_generic
set_attribute information_level 1
report sequential -deleted_seqs


puts "\[$thisf\] INFO: Generic synthesis finished. Resume to map."
if {[string is true $suspendScript]} { suspend } else { after $stageDelayMs } ;# Delay for readability

# Mapping; effort = {high (default) | low | medium | express}
set_attr syn_map_effort high
set_attribute information_level 2
syn_map
set_attribute information_level 1

puts "\[$thisf\] INFO: Mapping finished"
if {[string is true $suspendScript]} { suspend } else { after $stageDelayMs } ;# Delay for readability

###############################################################################
# Incremental optimization; effort = {high (default) | low | medium | express}
###############################################################################
puts "\[$thisf\] INFO: Optimizing synthesis"
after $stageDelayMs  ;# Delay for readability

set_attr syn_opt_effort high
syn_opt

if {[string is true $suspendScript]} { suspend } else { after $stageDelayMs } ;# Delay for readability

###############################################################################
# Write design, database snapshots and reports
###############################################################################
puts "\[$thisf\] INFO: Writing design, database snapshots and reports"
after $stageDelayMs  ;# Delay for readability
write_design -basename $path_saved_dir/$top_cell_name -innovus
write_snapshot -outdir $path_snapshot_dir -tag $top_cell_name

report qor > $path_report_dir/${top_cell_name}_QoR.rpt
report timing -lint -verbose > $path_report_dir/${top_cell_name}_TimingLint.rpt
report timing -worst 10 > $path_report_dir/${top_cell_name}_Timing.rpt
report design_rules > $path_report_dir/${top_cell_name}_DRC.rpt
report power > $path_report_dir/${top_cell_name}_Power.rpt
write_hdl > $path_export_dir/${top_cell_name}_post_syn.v
write_sdc > $path_export_dir/${top_cell_name}_post_syn.sdc

###############################################################################
# Export to LEC
###############################################################################
puts "\[$thisf\] INFO: Exporting to LEC" ;## LEC tool can be used for Logical Equivalence Checking
after $stageDelayMs  ;# Delay for readability
write_hdl > $path_lec_dir/verilog_final.v
write_do_lec -revised $path_lec_dir/verilog_final.v -log rtl2g.log > $path_lec_dir/rtl2g.do


puts "[info script] executed successfully." 

# Copy the runtime information (logfile) to the outputs as well, as it is useful to look through. 
cp -fv [get_attribute log_file] $path_output/genus.log
gui_show
