if {$::tcl_platform(platform) == "windows"} {
    set exeExtension ".exe"
    set pathSeparator ";"
} else {
    set exeExtension ""
    set pathSeparator ":"
}

global vcomCmd
global vlogCmd
global vlibCmd
global vmapCmd
global vsimCmd

set vcomCmd "vcom$exeExtension"
set vlogCmd "vlog$exeExtension"
set vlibCmd "vlib$exeExtension"
set vmapCmd "vmap$exeExtension"
set vsimCmd "vsim$exeExtension"
# set ::env(MODELSIM) [pwd]

#need to separate PATH on : character
set PATH $::env(PATH)
foreach dirName [split $PATH $pathSeparator] {
    if {[file exists $dirName/$vcomCmd]} {
        puts "Using $dirName as toolPath."
        set toolPath [file normalize $dirName]
        break
    }
}

set vcomCmd $toolPath/$vcomCmd
set vlogCmd $toolPath/$vlogCmd
set vlibCmd $toolPath/$vlibCmd
set vmapCmd $toolPath/$vmapCmd
set vsimCmd $toolPath/$vsimCmd

global ss
set ss ""

global BATCH_MODE
global SOCKET_MODE

proc simOpen {GUI_MODE} {
    global vsimCmd
    global ss
    # Check to see if we are currently running in a mentor tool
    # shell or if we are in batch mode.
    global BATCH_MODE
    set BATCH_MODE 0
    # Use the batch_mode command to verify that you are in Command Line Mode. stdout returns
    # “1” if you specify batch_mode while you are in Command Line Mode (vsim -c) or Batch Mode
    # (vsim -batch). 
    global SOCKET_MODE

    if {$GUI_MODE==1} {
        puts "in GUI_MODE"
        set BATCH_MODE 0        
    } elseif {[catch {batch_mode}]} {
        puts "setting BATCH_MODE to true"
        set BATCH_MODE 1
    } else {
        puts "setting BATCH_MODE to false"
        set BATCH_MODE 0
    }

    set SOCKET_MODE [expr $BATCH_MODE==1 || $GUI_MODE==1]

    if {$SOCKET_MODE == 1} {
        if {$BATCH_MODE == 1} {
            set batch_mode_str "-c "
        } else {
            set batch_mode_str ""
        }

        puts "MTCL - Starting Server in BATCH_MODE"
        # source ../toolchains/utility/socket/socket_server.tcl
        source $::env(MTCL_PATH)/toolchains/utility/socket/socket_server_oo.tcl

        # Create a new Socket Server
        set ss [SocketServer new]

        puts "MTCL - Starting Modelsim Client"
        set cmd_str "$vsimCmd $batch_mode_str\-do $::env(MTCL_PATH)/toolchains/utility/socket/socket_client.tcl"

        # >@stdout
        # if {[catch {exec {*}$cmd_str &}]} {
        #     puts "MTCL ERROR - launching socket client - $::errorInfo"
        #     # return false
        # }

        # Launch the simulator in the background and start up the socket client.
        eval {exec {*}$cmd_str >@stdout &}

        puts "MTCL - Entering Server Event Loop"
        $ss serverVwait
        puts "Connection established - moving on"

        # If we are in socket GUI mode then we could source the whole enivronment 
        # in the simulator shell through the socket.
        #  *open sim.tcl and push it over the socket
        #  *call mtcl_sim <test bench> <config file>
        # OR I can define some basic procs that wrap the socket send
        # that let the server side know what command to run. See below...
        set gui_mode_funcs "proc c {} {sockSend \"mtclCmd c\"}\n\
            proc cc {} {sockSend \"mtclCmd cc\"}\n\
            proc ltb {tb} {sockSend \"mtclCmd ltb \$tb\"}\n\
            proc rst {} {sockSend \"mtclCmd rst\"}\n\
            proc r {t \"\"} {sockSend \"mtclCmd r \$t\"}\n\
            proc rr {} {sockSend \"mtclCmd rr\"}\n\
            proc q {} {sockSend \"mtclCmd q\"}\n\
            proc qq {} {sockSend \"mtclCmd qq\"}\n\
            proc ver {} {sockSend \"mtclCmd ver\"}\n\
            proc cc {} {sockSend \"mtclCmd cc\"}\n"

        mentorExec $gui_mode_funcs

    } else {
        # We must be running from the simulator shell directly

   }
}

proc mentorExec {cmd} {
    global SOCKET_MODE
    global ss
    if {$SOCKET_MODE} {
        # puts "Send this cmd over the socket - $cmd"
        $ss send $cmd true
    } else {
        # puts "Run cmd locally - $cmd"
        # Hmmm, i had to remove "exec" from in front of {*} to get it to work in GUI mode
        if {[catch {{*}$cmd}]} {
            puts "MTCL ERROR - mentor - $::errorInfo"
        }
    }
}

proc simVersion {} {
    set version 0
    #Echo the simulator version
    mentorExec "vsim -version"
    # puts "version = $version"
    # lsearch -inline [split $version " "] {vsim}
    return $version
}

proc simHelp {} {
    return "\
---------------------------------------\n\
*useful information\n\
---------------------------------------";
}

proc simCompile {file library {args ""}} {
    #Create library if it doesn't exists
    if {![file isdirectory simlib/$library]} {
        file mkdir simlib/$library
        mentorExec "vlib simlib/$library"
        mentorExec "vmap $library simlib/$library"
    }

    set mentor_sim_args ""


    # Use switch here on file extension to ensure the proper command is built
    set cmd_str ""
    switch -glob [file extension $file] {
        ".sv" - ".v" {
            set cmd_str "vlog $file"
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
            set cmd_str "vcom $mentor_sim_args -quiet -work $library $file"
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
    mentorExec $cmd_str

    return true
}

# Elaborate is tricky with mentor tools. Once you elaborate the tool expects you to
# remain in that environment until you complete. This is fine for GUI mode but batch
# mode will simply spawn a vsim process that will never return... Historically, the 
# way around this is to utilize the -do flag to pass another script that will run
# the simulation. In the future, it would be possible but perhaps overkill to have 
# that script open a socket and execute commands passed to it from this environment.
# UPDATE:
#   Socket mode works well and is the solution going forward
proc simElaborate {tb library {args ""}} {
    mentorExec "vsim $library.$tb"
    mentorExec "add log -r /*"
    return true
}

proc simRun {tb {time ""}} {
    set cmd_str ""
    if {$time == ""} {
        set cmd_str "run -all"
    } else {
        set cmd_str "run $time ns"
    }

    # if {[catch {$cmd_str}]} {
    #     puts "No TB loaded! Load a test bench \"ltb\" <tb name>"
    # }
    mentorExec $cmd_str
    return true
}


proc simRestart {} {
    mentorExec "restart -f"
}


proc simQuit {} {
    mentorExec "quit"
}

proc simExit {} {
    global SOCKET_MODE
    global ss
    if {$SOCKET_MODE} {
        mentorExec "quit -f"
        $ss send "close"
    } else {
        quit -f
    }
}