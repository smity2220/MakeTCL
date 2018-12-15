# MakeTCL
File list management infrastructure for VHDL development

This framework simplifies VHDL development by attempting to standardize on a single pure TCL file list management system for both simulation and synthesis. I like to think of it as "the one file list to rule them all".

The file list structure is stored in a TCL dictionary, see [man page](https://www.tcl.tk/man/tcl/TclCmd/dict.htm). The key in the key/value pair is simply the file name. The value is a TCL list , see [man page](https://www.tcl.tk/man/tcl/TclCmd/list.htm), that contains at least the target library name followed by any number of optional arguments supported by the desired tool chain.

```tcl
set srcList [dict create \
    test2.vhd     "work OPTION1 OPTION2"\
]
```

Example Output of the unit test
```
% source mtcl_unit_test.tcl
MTCL - Entering .config file test.config
MTCL - Found a new .config file test2.config
MTCL - Entering .config file test2.config
MTCL - RECURSION ERROR - already called test.config
MTCL - Exiting  .config file test2.config
MTCL - Exiting  .config file test.config

Config File List
--------------------------------------------------------------------------
FILE
--------------------------------------------------------------------------
test.config
test2.config

Main Source File List
--------------------------------------------------------------------------
FILE                                                        LIBARAY
--------------------------------------------------------------------------
test1.vhd                                                   work
test2.vhd                                                   work

Test Bench List
--------------------------------------------------------------------------
TEST BENCH                                                  LIBARAY
--------------------------------------------------------------------------
test2_tb                                                    work

Vendor Library List
--------------------------------------------------------------------------
VENDOR FILE                                                 LIBARAY
--------------------------------------------------------------------------
unisim.vhd                                                  unisim
xpm.vhd                                                     xpm
```

# Sockets
A basic utility socket server client pair is under development. It is expected to be used to bridge between the main TCL shell and vendor TCL shells when the vendor tool doesn't support a batch mode.
