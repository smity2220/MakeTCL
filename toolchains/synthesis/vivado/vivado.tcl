
mTclLog 0 "MTCL VIVADO currently supports the following versions... none"


# proc newProj{platform} {

# }

# proc addToProj{file lib {opt ""}} {

# } 

proc synth {platform} {
	open_project -quiet $BUILD_DIR/$PROJ_NAME/$PROJ_NAME.xpr
	launch_runs synth_1
	wait_on_run synth_1
	close_project -quiet
}

proc impl {platform} {
	open_project -quiet $BUILD_DIR/$PROJ_NAME/$PROJ_NAME.xpr
	launch_runs impl_1 -to_step write_bitstream
	wait_on_run impl_1
	close_project -quiet
}

proc vivado_export_sdk {} {
	open_project -quiet $BUILD_DIR/$PROJ_NAME/$PROJ_NAME.xpr
	file mkdir @EXPORT_DIR
	write_sysdef -force \
	-hwdef "$BUILD_DIR/$PROJ_NAME/${PROJ_NAME}.runs/impl_1/$TARGET_PLATFORM.hwdef" \
	-bitfile "$BUILD_DIR/$PROJ_NAME/${PROJ_NAME}.runs/impl_1/$TARGET_PLATFORM.bit" \
	-meminfo "$BUILD_DIR/$PROJ_NAME/${PROJ_NAME}.runs/impl_1/$TARGET_PLATFORM.mmi" \
	$EXPORT_DIR/$TARGET_PLATFORM.hwdef
	close_project -quiet
}

proc vivado_add_elf {} {
	open_project -quiet $BUILD_DIR/$PROJ_NAME/$PROJ_NAME.xpr
	add_files -norecurse $ELF_FILENAME
	set_property SCOPED_TO_CELLS {microblaze_0} [get_files $ELF_FILENAME]
	set_property SCOPED_TO_REF mb [get_files $ELF_FILENAME]
	close_project -quiet
}

proc vivado_bitgen {} {
	open_project -quiet $BUILD_DIR/$PROJ_NAME/$PROJ_NAME.xpr
	# Not sure if this is required
	open_run impl_1
	write_bitstream -force -no_partial_bitfile -bin_file "$BUILD_DIR/$PROJ_NAME/${PROJ_NAME}.runs/impl_1/$TARGET_PLATFORM"
	close_project -quiet
}