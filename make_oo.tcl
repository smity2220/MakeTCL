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

    variable OPTIONS
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
    constructor {cfgFile cfgFileList options} {
        # set OPTIONS $options

        set OPT_LIST []
        set SRC_LIST []
        set CFG_LIST $cfgFileList
        set TB_LIST []
        set VLIB_LIST []

        set LOG_LVL [dict get $options LOG_LVL]
        set log [Logger new $LOG_LVL]

        $log print 1 "MTCL - Entering .config file $cfgFile"

        set CWD [file normalize [file dirname $cfgFile]]

        set OPT_LIST $options

        #Remove any previous definitions of the MTCL api procs
        unset -nocomplain MTCL_OPT
        unset -nocomplain MTCL_SRC
        unset -nocomplain MTCL_TB
        unset -nocomplain MTCL_VLIB

        #Source the .config file safely
        set cfgFile [file tail $cfgFile]
        if {[catch {source $CWD/$cfgFile}]} {
            $log print 0 "MTCL - ERROR SOURCING $CWD/$cfgFile!"
            return
        }
        #Add the current .config file name to the list of files
        #processed. This is used to detect recursion errors.
        lappend CFG_LIST [file normalize $CWD/$cfgFile]

        #Merge in the latest options. Must be done first as 
        #the options might change how the lists return
        if {[expr {[llength [info procs MTCL_OPT]] > 0}]} {
            set OPT_LIST  [dict merge $OPT_LIST  [MTCL_OPT]]
        }
        #Merge in the test bench lists
        if {[expr {[llength [info procs MTCL_TB]] > 0}]} {
            puts "merging TB_LIST"
            set TB_LIST   [dict merge $TB_LIST   [MTCL_TB $OPT_LIST]]
        }
        puts "TB_LIST = $TB_LIST"
        #Merge in the vendor library lists
        if {[expr {[llength [info procs MTCL_VLIB]] > 0}]} {
            set VLIB_LIST [dict merge $VLIB_LIST [MTCL_VLIB $OPT_LIST]]
        }


        #Save a copy of the source file list
        set local_src_list [MTCL_SRC $options]

        # Dump the contents from the new .config file
        # if {0} { dumpLists $local_src_list }

        #Iterate through the source file dictionary
        foreach fname [dict keys $local_src_list] {
            set opts [dict get $local_src_list $fname]
            if {[file extension $fname] == ".config"} {
                if {[lsearch -exact $CFG_LIST [file normalize $CWD/$fname] ] >= 0} {
                    $log print 0 "MTCL - RECURSION ERROR - already called $fname"
                } else {
                    #Recursively call makeLists if we find a new .config file
                    $log print 1 "MTCL - Found a new .config file $fname"
                    set recursive_oo [MTcl new $fname $CFG_LIST $OPT_LIST]

                    #not sure how to check for recursive presence of cfg files in post recursive format
                    #this instance needs to know what config files have come before.
                    set OPT_LIST  [dict merge $OPT_LIST  [$recursive_oo getOptList] ]
                    set SRC_LIST  [dict merge $SRC_LIST  [$recursive_oo getSrcList] ]
                    set TB_LIST   [dict merge $TB_LIST   [$recursive_oo getTbList] ]
                    set VLIB_LIST [dict merge $VLIB_LIST [$recursive_oo getVlibList] ]
                    set CFG_LIST                         [$recursive_oo getCfgList]
                }
            } else {
                #Add the non .config file to the master list
                set fullfname $CWD/$fname
                if {![dict exists $SRC_LIST $fullfname]} {
                    dict set SRC_LIST $fullfname $opts
                } else {
                    $log print 1 "MTCL - Skipping add of existing file: $fname in $CWD"
                }
            }
        }
        
        # set items [dict size $local_src_list]
        # $log print 0 "MTCL - Merging $items from $cfgFile"
        # set SRC_LIST [dict merge $SRC_LIST $local_src_list]

        $log print 1 "MTCL - Exiting  .config file $cfgFile"
        # dict set OPT_LIST ROOT_DIR $PWD
        # $log print 1 "MTCL - ReSetting ROOT_DIR to [dict get $OPT_LIST ROOT_DIR]"
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
        $log print 1 "--------------------------------------------------------------------------"
        $log print 1 $header
        $log print 1 "--------------------------------------------------------------------------"
        foreach item $l {
            $log print 1 "$item"
        }
    }
    # Private
    method DumpDict {d headers {formatStr "%-60s%-15s"}} {
        # $log print 0 $headers
        $log print 1 "--------------------------------------------------------------------------"
        $log print 1 [format $formatStr [lindex $headers 0] [lindex $headers 1]] 
        $log print 1 "--------------------------------------------------------------------------"
        foreach key [dict keys $d] {
            set value [dict get $d $key]
            $log print 1 [format $formatStr [file tail $key] "$value"] 
        }
    }

    # Public
    method dumpLists {} {
        # set formatStr {%-60s%-15s}

        $log print 1 "\nConfig File List"
        set header "FILE"
        my DumpList $CFG_LIST $header

        $log print 1 "\nMain Source File List"
        set headers {"FILE" "LIBARAY"}
        my DumpDict $SRC_LIST $headers

        $log print 1 "\nTest Bench List"
        set headers {"TEST BENCH" "LIBARAY"}
        my DumpDict $TB_LIST $headers

        $log print 1 "\nVendor Library List"
        set headers {"VENDOR FILE" "LIBARAY"}
        my DumpDict $VLIB_LIST $headers
    }
}
