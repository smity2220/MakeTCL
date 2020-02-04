proc src {file args} {
  set argv $::argv
  set argc $::argc
  set ::argv $args
  set ::argc [llength $args]
  set code [catch {uplevel [list source $file]} return]
  set ::argv $argv
  set ::argc $argc
  return -code $code $return
}

set MTCL_DIR [file normalize ".."]
set ROOT_DIR [file normalize "."]

src $MTCL_DIR/sim.tcl -t test_tb -f test.config -m $MTCL_DIR -r $ROOT_DIR