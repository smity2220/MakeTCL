set toolPath "C:/intelFPGA_pro/18.1/modelsim_ase/win32aloem"
global vcomCmd
set vcomCmd "$toolPath/vcom.exe"
global vlogCmd
set vlogCmd "$toolPath/vlog.exe"
global vlibCmd
set vlibCmd "$toolPath/vlib.exe"
global vmapCmd
set vmapCmd "$toolPath/vmap.exe"
global vsimCmd
set vsimCmd "$toolPath/vsim.exe"

# Check to see if we are currently running in a mentor tool
# shell or if we are in batch mode.
global BATCH_MODE
# Use the batch_mode command to verify that you are in Command Line Mode. stdout returns
# “1” if you specify batch_mode while you are in Command Line Mode (vsim -c) or Batch Mode
# (vsim -batch). 
global SOCKET_MODE
if {[catch {batch_mode}]} {
    puts "setting BATCH_MODE to true"
    set BATCH_MODE true
} else {
    puts "setting BATCH_MODE to false"
    set BATCH_MODE false
}



proc mentorExec {cmd} {
    global SOCKET_MODE
    if {$SOCKET_MODE} {
        # puts "Send this cmd over the socket - $cmd"
        sockSend $cmd
    } else {
        # Run it locally.
        if {[catch {exec {*}$cmd}]} {
            puts "MTCL ERROR - mentor - $::errorInfo"
        }
    }
}

proc simVersion {} {
    global BATCH_MODE
    global vsimCmd
    set version 0
    #Echo the simulator version
    if {$BATCH_MODE} {
        if {[catch {exec "$vsimCmd" -version}]} {
            puts "MTCL ERROR - mentor - $::errorInfo"
        } else {
            set version [exec "$vsimCmd" -version]
        }
    } else {
        set version [vsim -version]
    }
    # puts "version = $version"
    # lsearch -inline [split $version " "] {vsim}
    return $version
}

proc simHelp {} {
    global BATCH_MODE
    if {$BATCH_MODE} {
        puts "---------------------------------------"
        puts "Welcome to batch mode with Mentor"
        puts "  *useful information"
        puts "---------------------------------------"
    } else {
        puts "---------------------------------------"
        puts "Welcome to GUI mode with Mentor"
        puts "  *useful information"
        puts "---------------------------------------"
    }
}

proc simCompile {file library {args ""}} {
    global BATCH_MODE
    global vcomCmd
    global vlogCmd
    global vlibCmd
    global vmapCmd

    #Create library if it doesn't exists
    if {![file isdirectory $library]} {
        file mkdir work
        # if {$BATCH_MODE} {
        #     if {[catch {exec "$vlibCmd" $library}]} {
        #         puts "MTCL ERROR - mentor - $vlibCmd $library"
        #         puts "MTCL ERROR - mentor - $::errorInfo"
        #         return false
        #     }
        # } else {
        #     vlib $library
        # }
        mentorExec "vlib $library"

        #Map if needed
        # if {$BATCH_MODE} {
        #     if {[catch {exec "$vmapCmd" $library $library}]} {
        #         puts "MTCL ERROR - mentor - $vmapCmd $library $library"
        #         puts "MTCL ERROR - mentor - $::errorInfo"
        #         return false
        #     }
        # } else {
        #     vmap $library $library
        # }
        mentorExec "vmap $library $library"
    }

    set mentor_sim_args ""


    # Use switch here on file extension to ensure the proper command is built
    set cmd_str ""
    switch -glob [file extension $file] {
        ".sv" - ".v" {
            set cmd_str "$vlogCmd $file"
        }
        ".c*" {
            # TODO: C files for SV DPI integration. Not intending to support any other FLI. 
            set cmd_str ""
        }
        ".vh*" - ".pkg" - ".tb" {
            #Check the args to see if this tool supports any options
            if {[lsearch $args "VHDL_2008"] >= 0} {
                lappend mentor_sim_args "-2008"
            } else {
                lappend mentor_sim_args "-93"
            }
            set cmd_str "$vcomCmd $mentor_sim_args -quiet -work $library $file"
        }
        ".tcl" {
            # TCL files are special in that we just dive right in and source them
            # instead of passing through exec
            puts "MTCL - SIM - sourcing $filename"
            if {[catch {source $filename}]} {
                puts "MTCL ERROR - sourcing - $::errorInfo"
                return false    
            }
            return true
        }
        default {}
    }

    #Execute our command string appropriately based upon the mode
    # if {$BATCH_MODE} {
    #     # Use TCL list expansion {*} to pass the command string in as a list of arguments for exec
    #     if {[catch {exec {*}$cmd_str}]} {
    #         puts "MTCL ERROR - mentor compile - $::errorInfo"
    #         return false
    #     }
    # } else {
    #     # puts "$cmd_str"
    #     eval {*}$cmd_str
    # }
    mentorExec $cmd_str

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
    set cmd_str ""

    # if {$BATCH_MODE} {
    #     # UPDATE
    #     #   Using the stdout redirection capabilities of "exec" is close to what I want,
    #     #   though it still isn't perfect as it does jump you into a new TCL shell.
    #     #     set cmd_str "$vsimCmd -c $library.$tb"
    #     # THIS IS THE OLD COMMAND 
    #     set cmd_str "$vsimCmd -c $library.$tb -do \"run -all; quit\""
    #     # This version attempts to re-source the simulator scripts in the new shell... can't pass mentor as an arg though...
    #     # set cmd_str "$vsimCmd -c $library.$tb -do ../toolchains/simulators/simulator.tcl" 
    #     if {[catch {exec {*}$cmd_str >@stdout}]} { 
    #         # mTclLog 1 "MTCL ERROR - mentor elaborate - $vsimCmd -c $library.$tb -do run -all; quit"
    #         puts "MTCL ERROR - mentor elaborate - $::errorInfo"
    #         return false
    #     }
    # } else {
    #     vsim $library.$tb
    # }
    mentorExec "vsim $library.$tb"
    return true
}

proc simRun {tb {time ""}} {
    global vsimCmd
    global BATCH_MODE
    set cmd_str ""
    # if {$BATCH_MODE} {
    #     # Elaboration executes the run phase when in batch mode.
    #     set cmd_str "run -all"
    # } else {
        if {$time == ""} {
            set cmd_str "run -all"
        } else {
            set cmd_str "run $time ns"
        }
    # }

    # if {[catch {$cmd_str}]} {
    #     puts "No TB loaded! Load a test bench \"ltb\" <tb name>"
    # }
    mentorExec $cmd_str
    return true
}

# GUI mode only?
proc simRestart {} {
    # restart -f
    # if {[catch {restart -f}]} {
    #     puts "No TB loaded! Load a test bench \"ltb\" <tb name>"
    # }
    mentorExec "restart -f"
}

# GUI mode only?
proc simQuit {} {
    # quit
    # if {[catch {quit}]} {
    #     puts "No TB loaded! Load a test bench \"ltb\" <tb name>"
    # }
    mentorExec "quit"
}

# GUI mode only?
proc simExit {} {
    global SOCKET_MODE
    if {$SOCKET_MODE} {
        sockSend "close"
    } else {
        quit -f
    }
}




set SOCKET_MODE $BATCH_MODE
if {$SOCKET_MODE} {
    puts "MTCL - Starting Server"
    # source ../toolchains/utility/socket/socket_server.tcl
    source ../toolchains/utility/socket/socket_server_oo.tcl

    # Create a new Socket Server
    set ss [SocketServer new]

    puts "MTCL - Starting Modelsim Client"
    set cmd_str "$vsimCmd -c -do ../toolchains/utility/socket/socket_client.tcl"

    # >@stdout
    # if {[catch {exec {*}$cmd_str &}]} {
    #     puts "MTCL ERROR - launching socket client - $::errorInfo"
    #     # return false
    # }

    # Launch the simulator in the background and start up the socket client.
    eval {exec {*}$cmd_str >@stdout &}

    puts "MTCL - Entering Server Event Loop"
    $ss serverVwait
}



# vsim -c counter <infile >outfile

# if {[catch {exec "$vsimCmd" -c -do socket_client.tcl >@stdout &}]} {
    # puts "ERROR"
# }


# socket -server accept 12345   ;# pick your own port number...
# proc accept {channel host port} {
#     exec [info nameofexecutable] realScript.tcl \
#             <@$channel >@$channel 2>@$channel &
# }
# vwait forever                 ;# run the event loop to serve sockets...