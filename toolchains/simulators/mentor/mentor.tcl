set toolPath "C:/intelFPGA_pro/18.1/modelsim_ase/win32aloem"
global vcomCmd
set vcomCmd "$toolPath/vcom.exe"
global vlibCmd
set vlibCmd "$toolPath/vlib.exe"
global vmapCmd
set vmapCmd "$toolPath/vmap.exe"
global vsimCmd
set vsimCmd "$toolPath/vsim.exe"

# Check to see if we are currently running in a mentor tool
# shell or if we are in batch mode.
global BATCH_MODE
# Need to find a command to try to execute that would only exist in 
# the tool console. We can do a try catch on it to set the mode.
set BATCH_MODE true

proc simHelp {} {
    
}

proc simCompile {file library {args ""}} {
    global BATCH_MODE
    global vcomCmd
    global vlibCmd
    global vmapCmd

    #Create library if it doesn't exists
    if {![file isdirectory $library]} {
        file mkdir work
        if {$BATCH_MODE} {
            if {[catch {exec "$vlibCmd" $library}]} {
                mTclLog 0 "MTCL ERROR - mentor - $vlibCmd $library"
                mTclLog 0 "MTCL ERROR - mentor - $::errorInfo"
                return false
            }
        } else {
            vlib $library
        }

        #Map if needed
        if {$BATCH_MODE} {
            if {[catch {exec "$vmapCmd" $library $library}]} {
                mTclLog 0 "MTCL ERROR - mentor - $vmapCmd $library $library"
                mTclLog 0 "MTCL ERROR - mentor - $::errorInfo"
                return false
            }
        } else {
            vmap $library $library
        }
    }

    set mentor_sim_args ""
    #Check the args to see if this tool supports any options
    if {[lsearch $args "VHDL_2008"] >= 0} {
        lappend mentor_sim_args "-2008"
    } else {
        lappend mentor_sim_args "-93"
    }

    #Compile file into library
    if {$BATCH_MODE} {
        if {[catch {exec "$vcomCmd" -work $library $file}]} {
            mTclLog 1 "MTCL ERROR - mentor compile - $vcomCmd -work $library $file"
            mTclLog 0 "MTCL ERROR - mentor compile - $::errorInfo"
            return false
        }
    } else {
        mTclLog 0 "vcom $mentor_sim_args -work $library $file"
        vcom $mentor_sim_args -quiet -work $library $file 
    }
    return true
}

# Elaborate is tricky with mentor tools. Once you elaborate the tool expects you to
# remain in that environment until you complete. This is fine for GUI mode but batch
# mode will simply spawn a vsim process that will never return... Historically, the 
# way around this is to utilize the -do flag to pass another script that will run
# the simulation. In the future, it would be possible but perhaps overkill to have 
# that script open a socket and execute commands passed to it from this environment.
proc simElaborate {tb library {args ""}} {
    global vsimCmd
    global BATCH_MODE
    if {$BATCH_MODE} {
        if {[catch {exec "$vsimCmd" -c $library.$tb -do "run -all; quit"}]} {
            mTclLog 1 "MTCL ERROR - mentor elaborate - $vsimCmd -c $library.$tb -do run -all; quit"
            mTclLog 0 "MTCL ERROR - mentor elaborate - $::errorInfo"
            return false
        }
    } else {
        vsim $library.$tb
    }
    return true
}

proc simRun {tb {time ""}} {
    global vsimCmd
    global BATCH_MODE
    if {$BATCH_MODE} {
        # Elaboration executes the run phase when in batch mode.
    } else {
        if {$time == ""} {
            run -all
        } else {
            run $time ns
        }
    }

    return true
}

proc simRestart {} {
    restart -f
}