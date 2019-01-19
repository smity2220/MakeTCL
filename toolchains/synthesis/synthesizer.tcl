#This layer provides the high level user synthesis interface.
#This layer will make calls down to the appropriate synthesis tool chain.

#Options from the makeTcl layer will define what simulator we link to.
proc newSynthesizer {options} {
    # Pull in the simulator choice from the options
    set MTCL_DIR    [dict get $options MTCL_DIR]
    set synthesizer [dict get $options SYNTHESIZER]
    set major_ver   [dict get $options SYNTH_MAJOR_VER]
    set minor_ver   [dict get $options SYNTH_MINOR_VER]

    # -glob?
    switch -nocase $synthesizer {
        "quartus"  {
            source $MTCL_DIR/toolchains/synthesis/quartus/quartus.tcl
            newQuaruts $options
        }
        "vivado" {
            source $MTCL_DIR/toolchains/synthesis/vivado/vivado.tcl
            # TODO: newVivado $options
        }
        defualt {
            mTclLog 0 "MTCL SYNTH - ERROR - UNSUPPORTED SYNTHESIZER $synthesizer"
            return
        }
    }

# TODO: Decide if the tool chain should check or if the tool chain should 
# return a list of supported versions
    # Defined by the tool chain
        # versionCheck $major_ver $minor_ver
    # OR Return list of supported versions
        # set versions [getSupportedVersions]
    # Do the look up and error checking
        # ... stuff
    # OR a new tool chain file for each version?
        # source "vivado_$major_ver\_$minor_ver\.tcl"

    # new
}

# 
proc createProj {options} {
    global MTCL_SRC_LIST

    #TODO: look at options to determine these
    set platform [dict get $options PLATFORM]
    set family   [dict get $options FAMILY]
    set part     [dict get $options PART]

    # Backup old work/<platform> directory


    # Create new work directory


    # Call into the tool chain to define the project
    # using platform, family, part?
    newProj $platform

    # Add the files to the project
    # foreach fname [dict keys $MTCL_SRC_LIST] {
    #     set lib [dict get $MTCL_SRC_LIST $fname]
    #     if {[file exists $fname]} {
    #         if {[addToProj $fname $lib]} {
    #             mTclLog 1 "MTCL SYNTH - Added $fname into $lib"
    #         } 
    #     } else {
    #         mTclLog 0 "MTCL SYNTH - ERROR! - File missing $fname"
    #         return
    #     }
    # }   

}

proc synthesis {options} {
    set platform [dict get $options PLATFORM]

    #
    if {[catch {[synth $platform]}]} {
        puts "MTCL ERROR - SYNTH!"
        return
    }
}

proc implementation {options} {
    set platform [dict get $options PLATFORM]

    #
    if {[catch {[impl $platform]}]} {
        puts "MTCL ERROR - IMPLEMENTATION!"
        return
    }
}

proc bitGen {options} {

}

proc flashGen {options} {

}