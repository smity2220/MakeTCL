set toolPath "C:/intelFPGA_pro/18.1/modelsim_ase/win32aloem"
global vcomCmd
set vcomCmd "$toolPath/vcom.exe"
global vlibCmd
set vlibCmd "$toolPath/vlib.exe"
global vmapCmd
set vmapCmd "$toolPath/vlib.exe"
global vsimCmd
set vsimCmd "$toolPath/vsim.exe"

# Check to see if we are currently running in a mentor tool
# shell or if we are in batch mode.
global BATCH_MODE
# Need to find a command to try to execute that would only exist in 
# the tool console. We can do a try catch on it to set the mode.
set BATCH_MODE 0


proc compile {file library {args ""}} {
    global vcomCmd
    global vlibCmd
    global vmapCmd
    file mkdir work

    #Create library if it doesn't exists
    if {[catch {exec "$vlibCmd" $library}]} {
        mTclLog 0 "MTCL ERROR - mentor - $vlibCmd $library"
        mTclLog 0 "MTCL ERROR - mentor - $::errorInfo"
        return false
    }

    #Map if needed
    if {[catch {exec "$vmapCmd" $library $library}]} {
        mTclLog 0 "MTCL ERROR - mentor - $vmapCmd $library $library"
        mTclLog 0 "MTCL ERROR - mentor - $::errorInfo"
        return false
    }

    #TODO: Detect VHDL 2008 property

    #Compile file into library
    if {[catch {exec "$vcomCmd" -work $library $file}]} {
        mTclLog 1 "MTCL ERROR - mentor compile - $vcomCmd -work $library $file"
        mTclLog 0 "MTCL ERROR - mentor compile - $::errorInfo"
        return false
    }
    return true
}

# Elaborate is tricky with mentor tools. Once you elaborate the tool expects you to
# remain in that environment until you complete. This is fine for GUI mode but batch
# mode will simply spawn a vsim process that will never return... Historically, the 
# way around this is to utilize the -do flag to pass another script that will run
# the simulation. In the future, it would be possible but perhaps overkill to have 
# that script open a socket and execute commands passed to it from this environment.
proc elaborate {tb library {args ""}} {
    global vsimCmd
    if {[catch {exec "$vsimCmd" -c $library.$tb -do "run -all; quit"}]} {
        mTclLog 1 "MTCL ERROR - mentor elaborate - $vsimCmd -c $library.$tb -do run -all; quit"
        mTclLog 0 "MTCL ERROR - mentor elaborate - $::errorInfo"
        return false
    }
    return true
}

proc run {tb {time}} {
    # global toolPath
    # if {[catch {exec "$toolPath" -r $tb}]} {
    #     mTclLog 0 "MTCL ERROR - mentor run - "
    #     mTclLog 0 "MTCL ERROR - mentor run - $::errorInfo"
    #     return false
    # }
    return true
}
