set quartusPath "C:/intelFPGA_pro/18.1/quartus/bin64"
global quartusCmd
set quartusCmd "$quartusPath/qpro_sh.exe"

mTclLog 0 "MTCL QUARTUS currently supports the following versions... none"

# https://www.intel.com/content/www/us/en/programmable/documentation/sbv1513989262284.html

# quartus_sh [-h | --help[=<option|topic>] | -v]
# quartus_sh -g | --gui [<project_name>]
# quartus_sh <other options>
# quartus_sh -t <script file> [<script args>]
# quartus_sh -s
# quartus_sh --tcl_eval <tcl command>

# The question is, how do we launch the tool? Options are:
# *Use the -s for the interactive shell
#   - This has the classic problem with spawning a new shell.  
# *Use the --tcl_eval to do each command individually.
# *Use the -t and & to call the socket client

proc newQuaruts {options} {
	set MTCL_DIR    [dict get $options MTCL_DIR]

	# Start the socket server
	source $MTCL_DIR/toolchains/utility/socket/socket_server.tcl

	# Open Quartus and start the socket client
	if {[catch {exec "$quartusCmd" -t $MTCL_DIR/toolchains/utility/socket/socket_client.tcl &}]} {
		puts "socket client error!"
	}

}


proc newProj {platform} {
	global quartusCmd
	# exec "$quartusCmd" >@stdout
	# if {[catch {exec "$quartusCmd" -t ../../utility/socket/socket_client.tcl >@stdout}]} {
	# 	puts "newProj error"
	# } else {
			# -overwrite
		project_new "test_proj_name" -revision $platform
	# }
}

proc addToProj {src_list} {
	foreach filenm [dict keys $src_list] {
		set library [dict get $src_list $filenm]

		# Check for options added onto the end of the filename
		set options {}
		set fileopt [regexp -all -inline {\S+} $filenm]
		if { [length $fileopt] > 1 } {
			set filename [lindex $fileopt 0]
			mTclLog 0 "MTCL - BUILD - DON'T USE FILE OPTIONS"
			set options [lrange $fileopt 1 [llength $fileopt]]
		} else {
			set filename $filenm
		}

		# Check for options attached to the library
		set libOpt [regexp -all -inline {\S+} $library]
		if { [llength $libOpt] > 1 } {
			# Pull out the library from the front of the list
			set lib [lindex $libOpt 0]
			# Save off the options
			set opt [lrange $libOpt 1 [llength $libOpt]]
			# Combine the two option sets
			set options "$options $opt"
		}

		switch -glob [file extension $filename] {
			".sv" {
				set_global_assignment -name SYSTEMVERILOG_FILE $filename -library $lib
			}
			".v" {
				set_global_assignment -name VERILOG_FILE $filename -library $lib
			}
			".vh*" - ".pkg" {
				if {[lsearch $options "VHDL_2008"] >= 0} {
					set_global_assignment -name VHDL_FILE $filename -hdl_version VHDL_2008 -library $lib	
				} else {
					set_global_assignment -name VHDL_FILE $filename -library $lib
				}
			}
			".qip" {
				set_global_assignment -name QIP_FILE $filename
			}
			".qsys" {
				set_global_assignment -name QSYS_FILE $filename
			}
			".sdc" {
				set_global_assignment -name SDC_FILE $filename
			}
			".tcl" {
				mTclLog 0 "MTCL - BUILD - sourcing $filename"
				# TODO: surround with catch
				source $filename
			}
			default {}
		}
	}
} 

proc synth {} {

}

proc impl {} {

}
