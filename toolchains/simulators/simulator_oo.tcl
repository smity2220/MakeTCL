oo::class create Simulator {
    # variable MTCL_OBJ
    variable LAST_COMPILE_TIME 
    variable MTCL_SRC_LIST
    variable MTCL_TB_LIST
    variable log
    variable currTb

    constructor {mtcl} {
        # set MTCL_OBJ $mtcl

        set MTCL_OPT_LIST [$mtcl getOptList]
        set MTCL_SRC_LIST [$mtcl getSrcList]
        # method getCfgList  {} {return CFG_LIST}
        set MTCL_TB_LIST  [$mtcl getTbList]
        # method getVlibList {} {return VLIB_LIST}
        set log           [$mtcl getLogger]

        # Pull in the simulator choice from the options
        set simulator [dict get $MTCL_OPT_LIST SIMULATOR]
        switch -nocase $simulator {
            "ghdl"  {
                #TODO: abstract path to tool chains
                source ../toolchains/simulators/ghdl/ghdl.tcl
            }
            "modelsim" - "questasim"  {
                #TODO: abstract path to tool chains
                source ../toolchains/simulators/mentor/mentor.tcl
            }
            defualt {
                $log print 0 "MTCL SIM - ERROR - UNSUPPORTED SIMULATOR $simulator"
            }
        }

    }
    destructor {
        $log destroy
        Simulator destroy
    }

    #Incremental Re-compile
    method c {} {
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
                $log print 1000 "File modified time = $fileMtime"
                $log print 1000 "MTCL LAST_COMPILE_TIME = $LAST_COMPILE_TIME"
                if {[file mtime $fname] > $LAST_COMPILE_TIME} {
                    if {[simCompile $fname $lib $args]} {
                        $log print 0 "MTCL SIM - compiled $fname into $lib"
                    } 
                }
            } else {
                $log print 0 "MTCL SIM - WARNING! - File missing $fname"
                puts -nonewline "Press any key to continue... "
                flush stdout
                gets stdin
            }
        }

        # Get current time in seconds
        set LAST_COMPILE_TIME [clock seconds]
        set compile_duration [expr $start_compile_time-[clock seconds]]
        $log print 0 "MTCL SIM - finished compilation @ $LAST_COMPILE_TIME took $compile_duration seconds"
        # Save our compile time to a file
        set fp [open "LAST_COMPILE_TIME" "w"]
        puts -nonewline $fp $LAST_COMPILE_TIME
        close $fp
    }

    #Full Re-compilation
    method cc {} {
        set LAST_COMPILE_TIME 0
        # Save our compile time to a file
        set fp [open "LAST_COMPILE_TIME" "w"]
        puts -nonewline $fp $LAST_COMPILE_TIME
        close $fp
        # Call the incremental re-compile now that we've reset the time
        my c
    }

    #Load Test Bench
    method ltb {tb {args ""}} {
        my variable currTb
        set currTb $tb

        #Library lookup
        set lib [dict get $MTCL_TB_LIST $tb]

        simElaborate $tb $lib $args
    }

    method r {{time ""}} {
        my variable currTb
        simRun $currTb $time
    }

    method rst {} {
        simRestart
    }

    method rr {} {
        rst
        r
    }

    #Exit current test bench
    method q {} {

    }

    #Exit simulator
    method qq {} {

    }
}