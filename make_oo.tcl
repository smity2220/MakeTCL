oo::class create Logger {
    variable LOG_LVL
    constructor {lvl} {
        set LOG_LVL $lvl
    }
    destructor {
        Logger destroy
    }

    method getLogLvl {} {
        return $LOG_LVL
    }
    method setLogLvl {lvl} {
        set LOG_LVL $lvl
    }
    method print {lvl msg} {
        if {$lvl <= $LOG_LVL} {puts $msg}
    }
    method file {lvl msg {file ""}} {
        if {$lvl <= $LOG_LVL} {puts $msg}
    }
}

oo::class create MTcl {

    variable ROOT_DIR OPTIONS
    # Main File Lists
    variable OPT_LIST
    variable SRC_LIST
    variable CFG_LIST
    # Simulation Lists
    variable TB_LIST
    variable VLIB_LIST
    # Build Lists?

    variable log

    # root 
    constructor {cfgFile options} {
        # set ROOT_DIR $root
        # set OPTIONS $options

        set OPT_LIST []
        set SRC_LIST []
        set CFG_LIST []
        set TB_LIST []
        set VLIB_LIST []

        set log [Logger new 0]

        $log print 0 "MTCL - Entering .config file $cfgFile"
        set OPT_LIST $options 

        #Remove any previous definitions of the MTCL api procs
        # unset -nocomplain MTCL_OPT
        # unset -nocomplain MTCL_SRC
        # unset -nocomplain MTCL_TB
        # unset -nocomplain MTCL_VLIB

        #Source the .config file safely
        if {[catch {source $cfgFile}]} {
            puts "MTCL ERROR SOURCING $cfgFile!"
            return
        }
        #Add the current .config file name to the list of files
        #processed. This is used to detect recursion errors.
        lappend CFG_LIST $cfgFile

        #Merge in the latest options. Must be done first as 
        #the options might change how the lists return
        # if {info exists MTCL_OPT}  {
            set OPT_LIST  [dict merge $OPT_LIST  [MTCL_OPT]]
        # }
        #Merge in the test bench lists
        # if {info exists MTCL_TB}   {
            set TB_LIST   [dict merge $TB_LIST   [MTCL_TB $OPT_LIST]]
        # }
        #Merge in the vendor library lists
        # if {info exists MTCL_VLIB} {
            set VLIB_LIST [dict merge $VLIB_LIST [MTCL_VLIB $OPT_LIST]]
        # }


        #Save a copy of the source file list
        set local_src_list [MTCL_SRC $options]

        # Dump the contents from the new .config file
        # if {0} { dumpLists $local_src_list }

        #Iterate through the source file dictionary
        foreach fname [dict keys $local_src_list] {
            set opts [dict get $local_src_list $fname]
            if {[file extension $fname] == ".config"} {
                if {[lsearch -exact $CFG_LIST $fname] >= 0} {
                    $log print 0 "MTCL - RECURSION ERROR - already called $fname"
                } else {
                    #Recursively call makeLists if we find a new .config file
                    $log print 1 "MTCL - Found a new .config file $fname"
                    makeLists $fname $options
                }
            } else {
                #Add the non .config file to the master list
                dict append SRC_LIST $fname $opts
            }
        }


        # set items [dict size $local_src_list]
        # $log print 0 "MTCL - Merging $items from $cfgFile"
        # set SRC_LIST [dict merge $SRC_LIST $local_src_list]

        $log print 1 "MTCL - Exiting  .config file $cfgFile" 
    }

    destructor {
        # Clean up our logger
        $log destroy
        # Remove the class definition
        MTcl destroy
    }

    method getLogger   {} {return $log}
    method getOptList  {} {return $OPT_LIST}
    method getSrcList  {} {return $SRC_LIST}
    method getCfgList  {} {return $CFG_LIST}
    method getTbList   {} {return $TB_LIST}
    method getVlibList {} {return $VLIB_LIST}

    # Private 
    method DumpList {l header} {
        $log print 0 "--------------------------------------------------------------------------"
        $log print 0 $header
        $log print 0 "--------------------------------------------------------------------------"
        foreach item $l {
            $log print 0 "$item"
        }
    }
    # Private
    method DumpDict {d headers {formatStr "%-60s%-15s"}} {
        # $log print 0 $headers
        $log print 0 "--------------------------------------------------------------------------"
        $log print 0 [format $formatStr [lindex $headers 0] [lindex $headers 1]] 
        $log print 0 "--------------------------------------------------------------------------"
        foreach key [dict keys $d] {
            set value [dict get $d $key]
            $log print 0 [format $formatStr "$key" "$value"] 
        }
    }

    # Public
    method dumpLists {} {
        # set formatStr {%-60s%-15s}

        $log print 0 "\nConfig File List"
        set header "FILE"
        my DumpList $CFG_LIST $header

        $log print 0 "\nMain Source File List"
        set headers {"FILE" "LIBARAY"}
        my DumpDict $SRC_LIST $headers

        $log print 0 "\nTest Bench List"
        set headers {"TEST BENCH" "LIBARAY"}
        my DumpDict $TB_LIST $headers

        $log print 0 "\nVendor Library List"
        set headers {"VENDOR FILE" "LIBARAY"}
        my DumpDict $VLIB_LIST $headers
    }
}