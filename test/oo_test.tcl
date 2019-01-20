if {[catch {Simulator destroy}]} {}
if {[catch {Logger destroy}]} {}
if {[catch {MTcl destroy}]} {}


#-------------------------------
#Create a file list
#-------------------------------
source ../make_oo.tcl

#Define our options 
set options [dict create \
    ROOT_DIR            [ file dirname [ file normalize [ info script ] ] ] \
    SIMULATOR           "modelsim" \
    SYNTHESIZER         "vivado" \
    SYNTH_MAJOR_VER     0 \
    SYNTH_MINOR_VER     0 \
]

set test_file_list [MTcl new test.config $options]

$test_file_list dumpLists



#-------------------------------
#Simulate
#-------------------------------
source ../toolchains/simulators/simulator_oo.tcl

puts "Setup the simulation environment"
set sim [Simulator new $test_file_list]

# Get back to simple commands for the HMI
interp alias {} c {} $sim c
interp alias {} cc {} $sim cc
interp alias {} ltb {} $sim ltb
interp alias {} ltb {} $sim r
interp alias {} q {} $sim q
interp alias {} qq {} $sim qq

puts "Compile the file list (incremental)"
c

puts "Load the test bench"
ltb test_tb

puts "Run the test bench"
r

# #Print a summary of all test bench results
# # $sim dumpTbScores

puts "cleaning up oo_test"

# $test_file_list destroy