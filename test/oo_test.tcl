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

#Setup the simulation environment
# newSimulator $options
set sim [Simulator new $test_file_list]

#Compile the file list (incremental)
$sim c

#Load the test bench
$sim ltb test_tb

# #Run the test bench
# $sim r

# #Print a summary of all test bench results
# # $sim dumpTbScores

puts "cleaning up oo_test"

$test_file_list destroy