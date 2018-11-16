#This layer provides the high level user simulation interface.
#This layer will make calls down to the appropriate simulator tool
#chain in order to do file compilation.

#Options from the makeTcl layer will define what simulator we link to.
proc newSimulator {options} {
	#TODO: unset compile and elaborate

	set $simulator [dict get $options SIMULATOR]

	switch -nocase $simulator {
		"ghdl"  {
			#TODO: abstract path to tool chains
			source ../toolchains/simulators/ghdl/ghdl.tcl
		}
		defualt {
			mTclLog 0 "MTCL SIM - ERROR - UNSUPPORTED SIMULATOR"
		}
	}
}

#Incremental Re-compile
proc c {} {
	global MTCL_SRC_LIST

	# Check to see if there is already a saved compile time
	if {[file exists "LAST_COMPILE_TIME"]} {
		set fp [open "LAST_COMPILE_TIME" r]
		set LAST_COMPILE_TIME [read $fp]
		close $fp
	} else {
		set LAST_COMPILE_TIME 0
	}

    foreach fname [dict keys $MTCL_SRC_LIST] {
        set lib [dict get $MTCL_SRC_LIST $fname]
        if {[file exists $fname]} {
	        # Check to see if the file was modified since the last compile
	        set fileMtime [file mtime $fname] 
	        mTclLog 10 "File modified time = $fileMtime"
	        mTclLog 10 "MTCL LAST_COMPILE_TIME = $LAST_COMPILE_TIME"
	        if {[file mtime $fname] > $LAST_COMPILE_TIME} {
		        if {[compile $fname $lib]} {
			        mTclLog 0 "MTCL SIM - compiled $fname into $lib"
		        } 
		    }
		} else {
			mTclLog 0 "MTCL SIM - WARNING! - File missing $fname"

		}
    }

    # Get current time in seconds
	set LAST_COMPILE_TIME [clock seconds]
    mTclLog 10 "MTCL SIM - finished compilation @ $LAST_COMPILE_TIME"
    # Save our compile time to a file
	set fp [open "LAST_COMPILE_TIME" "w"]
	puts -nonewline $fp $LAST_COMPILE_TIME
	close $fp
}

#Full Re-compilation
proc cc {} {
	set LAST_COMPILE_TIME 0
	# Save our compile time to a file
	set fp [open "LAST_COMPILE_TIME" "w"]
	puts -nonewline $fp $LAST_COMPILE_TIME
	close $fp
	# Call the incremental re-compile now that we've reset the time
	c
}

#Load Test Bench
proc ltb {tb {args ""}} {
	elaborate $tb $args
	run $tb
}

proc r {} {

}

proc rr {} {
	
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
