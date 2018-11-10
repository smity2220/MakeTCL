#This layer provides the high level user simulation interface.
#This layer will make calls down to the appropriate simulator tool
#chain in order to do file compilation.

#Options from the makeTcl layer will define what simulator we link to.
proc newSimulator {options} {
	#TODO: unset compile and elaborate
	#switch {$simulator} {
	source ../toolchains/simulators/ghdl/ghdl.tcl
	#}
}

#Full Re-compilation
proc cc {} {
	global MTCL_SRC_LIST
    foreach fname [dict keys $MTCL_SRC_LIST] {
        set lib [dict get $MTCL_SRC_LIST $fname]
        # mTclLog 0 [format $formatStr "$fname" "$lib"]
        compile $fname $lib
    }
}

#Incremental Re-compile
proc c {} {

}

#Load Test Bench
proc ltb {tb} {
	elaborate $tb
	run $tb
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
