#-------------------------------
#Create a file list
#-------------------------------
source ../make.tcl

#Define our options 
set options [dict create \
	ROOT_DIR			[ file dirname [ file normalize [ info script ] ] ] \
	SIMULATOR 			"ghdl" \
]

#Generate the file list
makeLists test.config $options

#Print the lists
dumpLists


#-------------------------------
#Compile and simulate
#-------------------------------
source ../toolchains/simulators/simulator.tcl
newSimulator 0
cc
