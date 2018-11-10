#-------------------------------
#Create a file list
#-------------------------------
source ../make.tcl

#Define our options 
set options []

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
