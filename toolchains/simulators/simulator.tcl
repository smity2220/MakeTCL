#This layer provides the high level user simulation interface.
#This layer will make calls down to the appropriate simulator tool
#chain in order to do file compilation.

#Options from the makeTcl layer will define what simulator we link to.
proc newSimulator {options} {

}

#Full Re-compilation
proc cc {} {

}

#Incremental Re-compile
proc c {} {

}

#Load Test Bench
proc ltb {} {

}

#Exit current test bench
proc q {} {

}

#Exit simulator
proc qq {} {

}

#Save the test bench error count
proc saveTbScore {} {

}

#Print out a list of all test bench status
proc dumpTbScores {} {

}
