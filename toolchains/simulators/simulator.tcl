#This layer provides the high level user simulation interface.
#This layer will make calls down to the appropriate simulator tool
#chain in order to do file compilation.

if {$argc > 0} {
    puts "we have args = $argc"
}

#Options from the makeTcl layer will define what simulator we link to.
proc newSimulator {options} {
    #TODO: unset compile and elaborate

    # Pull in the simulator choice from the options
    set simulator [dict get $options SIMULATOR]
    set MTCL_DIR      [dict get $options MTCL_DIR]

    switch -nocase $simulator {
        "ghdl"  {
            #TODO: abstract path to tool chains
            source $MTCL_DIR/toolchains/simulators/ghdl/ghdl.tcl
        }
        "modelsim" - "questasim"  {
            #TODO: abstract path to tool chains
            source $MTCL_DIR/toolchains/simulators/mentor/mentor.tcl
        }
        defualt {
            mTclLog 0 "MTCL SIM - ERROR - UNSUPPORTED SIMULATOR $simulator"
        }
    }
}

proc h {} {
    set formatStr "%-20s%-15s"
    mTclLog 0 [simVersion]
    mTclLog 0 "--------------------------------------------------------------------------"
    mTclLog 0 [format $formatStr "COMMAND" "DESCRIPTION"] 
    mTclLog 0 "--------------------------------------------------------------------------"
    mTclLog 0 [format $formatStr "c"        "Incremental Re-compile"]
    mTclLog 0 [format $formatStr "cc"       "Full Re-compile"]
    mTclLog 0 [format $formatStr "ltb"      "Load Test Bench"]
    mTclLog 0 [format $formatStr "rst"      "Reset Simulation"]
    mTclLog 0 [format $formatStr "r <time>" "Run Simulation"]
    mTclLog 0 [format $formatStr "rr"       "Reset and Run"]
    mTclLog 0 [format $formatStr "q"        "Exit the current simulation"]
    mTclLog 0 [format $formatStr "qq"       "Exit the simulator"]

    #Call the tool chain specific help
    simHelp
}

#Incremental Re-compile
proc c {} {
    global MTCL_SRC_LIST

    set start_compile_time [clock seconds]

    # Check to see if there is already a saved compile time
    if {[file exists "LAST_COMPILE_TIME"]} {
        set fp [open "LAST_COMPILE_TIME" r]
        set LAST_COMPILE_TIME [read $fp]
        close $fp
    } else {
        set LAST_COMPILE_TIME 0
    }

    foreach fname [dict keys $MTCL_SRC_LIST] {
        set lib_options [dict get $MTCL_SRC_LIST $fname]
        set lib [lindex $lib_options 0]
        set args [lreplace $lib_options 0 0]
        if {[file exists $fname]} {
            # Check to see if the file was modified since the last compile
            set fileMtime [file mtime $fname] 
            mTclLog 1000 "File modified time = $fileMtime"
            mTclLog 1000 "MTCL LAST_COMPILE_TIME = $LAST_COMPILE_TIME"
            if {[file mtime $fname] > $LAST_COMPILE_TIME} {
                if {[simCompile $fname $lib $args]} {
                    mTclLog 0 "MTCL SIM - compiled $fname into $lib"
                } 
            }
        } else {
            mTclLog 0 "MTCL SIM - WARNING! - File missing $fname"
            puts -nonewline "Press any key to continue... "
            flush stdout
            gets stdin
        }
    }

    # Get current time in seconds
    set LAST_COMPILE_TIME [clock seconds]
    set compile_duration [expr $start_compile_time-[clock seconds]]
    mTclLog 0 "MTCL SIM - finished compilation @ $LAST_COMPILE_TIME took $compile_duration seconds"
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

global currTb
#Load Test Bench
proc ltb {tb {args ""}} {
    global currTb
    set currTb $tb

    #Library lookup
    global MTCL_TB_LIST
    set lib [dict get $MTCL_TB_LIST $tb]

    simElaborate $tb $lib $args
}

proc r {{time ""}} {
    global currTb
    simRun $currTb $time
}

proc rst {} {
    simRestart
}

proc rr {} {
    rst
    r
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
