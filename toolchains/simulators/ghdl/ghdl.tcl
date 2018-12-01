set ghdlPath "C:/Program Files (x86)/Ghdl/bin"
global ghdlCmd
set ghdlCmd "$ghdlPath/ghdl.exe"

proc compile {file library {args ""}} {
    global ghdlCmd
    file mkdir work
    # exec "$ghdlCmd" -a --workdir=$library $file
    if {[catch {exec "$ghdlCmd" -a --workdir=$library $file}]} {
        mTclLog 1 "MTCL ERROR - ghdl compile - $ghdlCmd -a --workdir=$library $file"
        mTclLog 0 "MTCL ERROR - ghdl compile - $::errorInfo"
        return false
    }
    return true
}

proc elaborate {tb library {args ""}} {
    global ghdlCmd
    if {[catch {exec "$ghdlCmd" -e --workdir=$library $tb}]} {
        mTclLog 1 "MTCL ERROR - ghdl elaborate - $ghdlCmd -e --workdir=$library $tb"
        mTclLog 0 "MTCL ERROR - ghdl elaborate - $::errorInfo"
        return false
    }
    return true
}

proc run {tb {time}} {
    global ghdlCmd
    if {[catch {exec "$ghdlCmd" -r $tb}]} {
        mTclLog 0 "MTCL ERROR - ghdl run - $ghdlCmd -r $tb"
        mTclLog 0 "MTCL ERROR - ghdl run - $::errorInfo"
        return false
    }
    return true
}

# ghdl --clean --workdir=work

# ghdl --remove --workdir=work

# --ieee=synopsys -fexplicit