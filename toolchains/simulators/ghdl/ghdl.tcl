set ghdlPath "C:/Program Files (x86)/Ghdl/bin"
global ghdlCmd
set ghdlCmd "$ghdlPath/ghdl.exe"

proc compile {file library} {
	global ghdlCmd
	file mkdir work
    if {[catch {exec "$ghdlCmd" -a --workdir=$library $file}]} {
        mTclLog 0 "MTCL ERROR - ghdl compile - $ghdlCmd -a --workdir=$library $file"
    }
}

proc elaborate {tb library} {
	global ghdlCmd
	if {[catch {exec "$ghdlCmd" -e --workdir=$library $tb}]} {
        mTclLog 0 "MTCL ERROR - ghdl elaborate - $ghdlCmd -e --workdir=$library $tb"
    }
}

proc run {tb} {
	set cmd "ghdl -r $tb"
	mTclLog 0 "ghdl run - $cmd"
	if {[catch {exec $cmd}]} {
        mTclLog 0 "MTCL ERROR - ghdl run - $cmd"
    }
}

# ghdl --clean --workdir=work

# ghdl --remove --workdir=work

# --ieee=synopsys -fexplicit