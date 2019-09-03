if {[catch {Simulator destroy}]} {}
if {[catch {Logger destroy}]} {}
if {[catch {MTcl destroy}]} {}

set MTCL_DIR ".."

#-------------------------------
#Create a file list
#-------------------------------
source $MTCL_DIR/make_oo.tcl

#Define our options 
set options [dict create \
    ROOT_DIR            [ file dirname [ file normalize [ info script ] ] ] \
    MTCL_DIR            $MTCL_DIR \
    SIMULATOR           "modelsim" \
    SYNTHESIZER         "vivado" \
    SYNTH_MAJOR_VER     0 \
    SYNTH_MINOR_VER     0 \
]

set test_file_list [MTcl new test.config [] $options]

$test_file_list dumpLists



#-------------------------------
#Simulate
#-------------------------------
source $MTCL_DIR/toolchains/simulators/simulator_oo.tcl

puts "Setup the simulation environment"
set sim [Simulator new "$test_file_list" "$options"]

# Get back to simple commands for the HMI
interp alias {} c {} $sim c
interp alias {} cc {} $sim cc
interp alias {} ltb {} $sim ltb
interp alias {} r {} $sim r
interp alias {} rr {} $sim rr
interp alias {} rst {} $sim rst
interp alias {} q {} $sim q
interp alias {} qq {} $sim qq

puts "Compile the file list (incremental)"
c

puts "Load the test bench"
# TODO - SOCKET: This needs to turn into a "blocking" socket exchange. Currently 
#				 we issue the ltb then the r right after and the simulator will 
#				 never have the tb loaded in time to be ready for the r (run). 
ltb test_tb

puts "Run the test bench"
r

# #Print a summary of all test bench results
# # $sim dumpTbScores

puts "cleaning up oo_test"
$test_file_list destroy
