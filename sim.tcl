#!/usr/bin/env tclsh
package require cmdline

set options {
    {c                          "Clean"}
    {g                          "GUI Mode"}
    {i                          "Interactive Shell"}
    {oo.arg "1"                 "Object Oriented Environment"}
    {t.arg ""                   "Test Bench"}
    {f.arg ""                   "Config File"}
}
    # {r.arg "$::argv0"           "Root Path (Defaults to $::argv0)"}
    # {m.arg "$::env(MTCL_PATH)"  "MTCL Path (Defaults to $::env(MTCL_PATH))"}

set usage ": MyCommandName \[options] filename ...\noptions:"
try {
    array set params [::cmdline::getoptions argv $options $usage]
} trap {CMDLINE USAGE} {msg o} {
    # Trap the usage signal, print the message, and exit the application.
    # Note: Other errors are not caught and passed through to higher levels!
    puts $msg
    exit 1
}

if {[catch {Simulator destroy}]} {}
if {[catch {Logger destroy}]} {}
if {[catch {MTcl destroy}]} {}


# Always redefine the MAKE_TCL environment variable to be
# the location of this file. Someone else took the trouble
# to call this file so it must be what they want.
set ::env(MTCL_PATH) [file dirname [file normalize [info script]]]
set WORK_DIR "[file dirname [file normalize [info script 0]]]/work"
set CONFIG_FILE $params(f)

puts "MTCL Setup - MTCL_DIR    = $::env(MTCL_PATH)"
puts "MTCL Setup - WORK_DIR    = $WORK_DIR"
puts "MTCL Setup - CONFIG_FILE = $CONFIG_FILE"

#Define our options structure
set options [dict create \
    WORK_DIR            $WORK_DIR \
    MTCL_DIR            $::env(MTCL_PATH) \
    SIMULATOR           "modelsim" \
    SYNTHESIZER         "vivado" \
    SYNTH_MAJOR_VER     0 \
    SYNTH_MINOR_VER     0 \
]

#-------------------------------
#Setup the MTCL environment
# Both OO and non-OO paths supported for now
#-------------------------------
if {$params(oo) == 1} {
    source $::env(MTCL_PATH)/make_oo.tcl
    set test_file_list [MTcl new $CONFIG_FILE {} $options]
    $test_file_list dumpLists
} else {\
    puts "Creating file lists"
    source $::env(MTCL_PATH)/make.tcl
    makeLists $CONFIG_FILE $options
    dumpLists
}

#-------------------------------
# Setup a sandbox to play in
#-------------------------------
if {[info exists params(c)]} {
    puts "cleaning simulation work directory "
    file delete -force $WORK_DIR
}
file mkdir $WORK_DIR
cd $WORK_DIR


#-------------------------------
#Simulate
#-------------------------------
if {$params(oo) == 1} {
    puts "Setup the oo simulation environment"
    source $::env(MTCL_PATH)/toolchains/simulators/simulator_oo.tcl
    puts "Setup the simulation environment"
    set sim [Simulator new $test_file_list]

    # Get back to simple commands for the HMI
    interp alias {} c {} $sim c
    interp alias {} cc {} $sim cc
    interp alias {} ltb {} $sim ltb
    interp alias {} r {} $sim r
    interp alias {} rr {} $sim rr
    interp alias {} rst {} $sim rst
    interp alias {} q {} $sim q
    interp alias {} qq {} $sim qq

} else {
    source $::env(MTCL_PATH)/toolchains/simulators/simulator.tcl
    puts "Setup the simulation environment"
    newSimulator $options

}


puts "Compile the file list (incremental)"
c

puts "Load the test bench ($params(t))"
# TODO - SOCKET: This needs to turn into a "blocking" socket exchange. Currently 
#                we issue the ltb then the r right after and the simulator will 
#                never have the tb loaded in time to be ready for the r (run).
ltb $params(t)

# puts "Run the test bench"
r

#Print a summary of all test bench results
# $sim dumpTbScores

if {$params(oo) == 1} {
    puts "cleaning up oo_test"
    $test_file_list destroy
}