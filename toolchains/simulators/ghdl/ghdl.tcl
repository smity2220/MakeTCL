set ghdlPath "C:/Program Files (x86)/Ghdl/bin"
global ghdlCmd
set ghdlCmd "$ghdlPath/ghdl.exe"

proc simHelp {} {
    # set helpList [dict create \
    #     VENDOR     "xilinx"\
    #     FAMILY     "7series"\
    # ]
    # return $optList
}

proc simCompile {file library {args ""}} {
    global ghdlCmd
    file mkdir work
    set ghdlArgs "-a -fpsl --ieee=standard --workdir=$library $file"
    if {[catch {exec "$ghdlCmd" {*}$ghdlArgs}]} {
        # puts "MTCL ERROR - ghdl compile - $ghdlCmd $ghdlArgs"
        puts "MTCL ERROR - ghdl compile - '$ghdlArgs' \n\t$::errorInfo"
        return false
    }
    return true
}

proc simElaborate {tb library {args ""}} {
    global ghdlCmd
    if {[catch {exec "$ghdlCmd" -e --workdir=$library $tb}]} {
        puts "MTCL ERROR - ghdl elaborate - $ghdlCmd -e --workdir=$library $tb"
        puts "MTCL ERROR - ghdl elaborate - $::errorInfo"
        return false
    }
    return true
}

proc simRun {tb {time}} {
    global ghdlCmd
    if {[catch {exec "$ghdlCmd" -r $tb}]} {
        puts "MTCL ERROR - ghdl run - $ghdlCmd -r $tb"
        puts "MTCL ERROR - ghdl run - $::errorInfo"
        return false
    }
    return true
}

# ghdl --clean --workdir=work

# ghdl --remove --workdir=work

# --ieee=synopsys -fexplicit