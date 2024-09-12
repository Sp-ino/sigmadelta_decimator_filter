########################### -- Genus Library Setup -- ############################
# Filename    : libs_setup_genus.tcl
# Description : Genus setup script pointing to the timing libraries of interest
#
# Created     : 27/11/2017 David Rivas Marchena (DRM)
# Edited      : 16/10/2018 Iain Sedgwick - Edited for use with Tower
# Edited      : 05/01/2021 Seddik Benhammadi- Edited for C100 and new std library
# Edited      : 24/08/2021 Deividas Krukauskas (DK)
# Edited      : 08/06/2022 Herman Larsen (HL)
######################################################################################
puts "Executing [info script] ... " 

# Add paths for Standard Cells
set my_search_path ""
lappend my_search_path /projects/TOWER18CIS/LOGIC/tsl18fs191svt_Rev_2022.03/lib/liberty
set_attribute lib_search_path $my_search_path

# Timing models
set timing_lib ""

# Select one of the following corners (ideally run all three once SDCs are verified). Power estimates best taken from fast fast corner.
# SLOW PVT CORE = {slow, 1.62V, 150deg}
lappend timing_lib tsl18fs191svt_ss_1p62v_150c.lib

# TYPICAL PVT CORE = {typical, 1.8V, 25deg}
#lappend timing_lib tsl18fs191svt_tt_1p8v_25c.lib

# FAST PVT CORE = {FAST, 1.98V, -40deg}
#lappend timing_lib tsl18fs191svt_ff_1p98v_m40c.lib 

puts "\[[file tail [info script] ]\] INFO: Setting up Timing Library"
set_attribute library $timing_lib

puts "[info script] executed successfully." 
