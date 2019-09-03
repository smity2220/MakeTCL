#-------------------------------
#Create a file list
#-------------------------------
set MTCL_DIR ".."

#Define our options 
set options [dict create \
    ROOT_DIR            [ file dirname [ file normalize [ info script ] ] ] \
    MTCL_DIR            "$MTCL_DIR" \
    SIMULATOR           "modelsim" \
    SYNTHESIZER         "vivado" \
    SYNTH_MAJOR_VER     0 \
    SYNTH_MINOR_VER     0 \
]

source $MTCL_DIR/make.tcl

#Generate the file list
makeLists test.config $options

#Print the lists
dumpLists


#-------------------------------
#Simulate
#-------------------------------
source ../toolchains/simulators/simulator.tcl

#Setup the simulation environment
newSimulator $options

#Compile the file list (incremental)
c

#Load the test bench
ltb test_tb

#Run the test bench
r

#Print a summary of all test bench results
dumpTbScores


#-------------------------------
#Build
#-------------------------------
source ../toolchains/synthesis/synthesizer.tcl

#Setup the build environment
newSynthesizer $options

#Create the project
# createProj $options

#Synthesize the design
# synthesis $options

#Implement the design
# implementation $options

#Bit file gen

#Flash file gen

