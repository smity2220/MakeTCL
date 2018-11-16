global LOG_LVL
set LOG_LVL 0

proc getMTclLogLvl {} {
    global LOG_LVL
    return $LOG_LVL
}
proc setMTclLogLvl {lvl} {
    global LOG_LVL
    set LOG_LVL $lvl
}
proc mTclLog {lvl msg} {
    if {$lvl <= [getMTclLogLvl]} {puts $msg}
}

# --------------------------------------------------
# Main File Lists
global MTCL_OPT_LIST
set MTCL_OPT_LIST []
global MTCL_SRC_LIST
set MTCL_SRC_LIST []
global MTCL_CFG_LIST
set MTCL_CFG_LIST []

# Simulation Lists
global MTCL_TB_LIST
set MTCL_TB_LIST []
global MTCL_VLIB_LIST
set MTCL_VLIB_LIST []

# Build Lists?



proc makeLists {cfgFile options} {
    mTclLog 0 "MTCL - Entering .config file $cfgFile"
    global MTCL_CFG_LIST
    global MTCL_OPT_LIST
    global MTCL_SRC_LIST
    global MTCL_TB_LIST
    global MTCL_VLIB_LIST

    set MTCL_OPT_LIST $options 

    #Remove any previous definitions of the MTCL api procs
    unset -nocomplain MTCL_OPT
    unset -nocomplain MTCL_SRC
    unset -nocomplain MTCL_TB
    unset -nocomplain MTCL_VLIB

    #Source the .config file safely
    if {[catch {source $cfgFile}]} {
        puts "MTCL ERROR SOURCING $cfgFile!"
        return
    }
    #Add the current .config file name to the list of files
    #processed. This is used to detect recursion errors.
    lappend MTCL_CFG_LIST $cfgFile

    #Merge in the latest options. Must be done first as 
    #the options might change how the lists return
    # if {info exists MTCL_OPT}  {
        set MTCL_OPT_LIST  [dict merge $MTCL_OPT_LIST  [MTCL_OPT]]
    # }
    #Merge in the test bench lists
    # if {info exists MTCL_TB}   {
        set MTCL_TB_LIST   [dict merge $MTCL_TB_LIST   [MTCL_TB $MTCL_OPT_LIST]]
    # }
    #Merge in the vendor library lists
    # if {info exists MTCL_VLIB} {
        set MTCL_VLIB_LIST [dict merge $MTCL_VLIB_LIST [MTCL_VLIB $MTCL_OPT_LIST]]
    # }


    #Save a copy of the source file list
    set local_src_list [MTCL_SRC $options]

    # Dump the contents from the new .config file
    # if {0} { dumpLists $local_src_list }

    #Iterate through the source file dictionary
    foreach fname [dict keys $local_src_list] {
        set opts [dict get $local_src_list $fname]
        if {[file extension $fname] == ".config"} {
            if {[lsearch -exact $MTCL_CFG_LIST $fname] >= 0} {
                mTclLog 0 "MTCL - RECURSION ERROR - already called $fname"
            } else {
                #Recursively call makeLists if we find a new .config file
                mTclLog 1 "MTCL - Found a new .config file $fname"
                makeLists $fname $options
            }
        } else {
            #Add the non .config file to the master list
            dict append MTCL_SRC_LIST $fname $opts
        }
    }


    # set items [dict size $local_src_list]
    # mTclLog 0 "MTCL - Merging $items from $cfgFile"
    # set MTCL_SRC_LIST [dict merge $MTCL_SRC_LIST $local_src_list]

    mTclLog 1 "MTCL - Exiting  .config file $cfgFile"  
}

proc dumpList {l header} {
    mTclLog 0 "--------------------------------------------------------------------------"
    mTclLog 0 $header
    mTclLog 0 "--------------------------------------------------------------------------"
    foreach item $l {
        mTclLog 0 "$item"
    }
}
proc dumpDict {d headers {formatStr "%-60s%-15s"}} {
    # mTclLog 0 $headers
    mTclLog 0 "--------------------------------------------------------------------------"
    mTclLog 0 [format $formatStr [lindex $headers 0] [lindex $headers 1]] 
    mTclLog 0 "--------------------------------------------------------------------------"
    foreach key [dict keys $d] {
        set value [dict get $d $key]
        mTclLog 0 [format $formatStr "$key" "$value"] 
    }
}

proc dumpLists {{src_list "global"}} {
    global MTCL_SRC_LIST
    if {$src_list == "global"} {
        set src_list $MTCL_SRC_LIST
    }

    global MTCL_CFG_LIST
    global MTCL_TB_LIST
    global MTCL_VLIB_LIST

    # set formatStr {%-60s%-15s}

    mTclLog 0 "\nConfig File List"
    set header "FILE"
    dumpList $MTCL_CFG_LIST $header

    mTclLog 0 "\nMain Source File List"
    set headers {"FILE" "LIBARAY"}
    dumpDict $src_list $headers

    mTclLog 0 "\nTest Bench List"
    set headers {"TEST BENCH" "LIBARAY"}
    dumpDict $MTCL_TB_LIST $headers

    mTclLog 0 "\nVendor Library List"
    set headers {"VENDOR FILE" "LIBARAY"}
    dumpDict $MTCL_VLIB_LIST $headers
}

