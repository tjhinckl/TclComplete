iabbrev 2D_check_legality	nypd_check_legality 
iabbrev 2D_legalizer_toolbox	nypd_toolbox 
iabbrev ac	all_connected 
iabbrev alc	als_add_to_last_command 
iabbrev cb	current_block 
iabbrev ch	als_change_highlight 
iabbrev cl	current_lib 
iabbrev cr	::fp::create_row 
iabbrev cs	change_selection 
iabbrev csa	change_selection -add 
iabbrev fc	filter_collection 
iabbrev ga	get_attribute 
iabbrev gb	get_bounds 
iabbrev gc	get_cells 
iabbrev gch	get_cells -hierarchical 
iabbrev gh	als_get_highlight 
iabbrev gn	get_nets 
iabbrev gobl	get_objects_by_location 
iabbrev gon	get_object_name 
iabbrev gp	get_pins 
iabbrev gs	get_selection 
iabbrev gt	get_terminals 
iabbrev gtpmax	get_timing_paths -delay_type max 
iabbrev gtpmin	get_timing_paths -delay_type min 
iabbrev gw	get_shapes -filter "shape_type==path" 
iabbrev h	history -h 
iabbrev hg	als_history_grep 
iabbrev la	list_attributes -application -nosplit 
iabbrev lag	als_list_attributes_grep 
iabbrev lb	list_blocks 
iabbrev lcg	start_gui; source $::env(SD_BUILD2)/utils/gui.bootstrap.tcl 
iabbrev ob	open_block 
iabbrev ol	open_lib 
iabbrev pac	als_print_all_connected 
iabbrev pc	als_print_collection 
iabbrev pl	als_print_list 
iabbrev pop	als_pop_from_cell 
iabbrev push	als_push_to_cell 
iabbrev qtcl_activate_widget_slot	qtcl_activate_slot 
iabbrev qtcl_add_widget_property	qtcl_add_property 
iabbrev qtcl_check_widget	qtcl_check 
iabbrev qtcl_connect_widgets	qtcl_connect 
iabbrev qtcl_create_widget	qtcl_create 
iabbrev qtcl_destroy_widget	qtcl_destroy 
iabbrev qtcl_disconnect_widgets	qtcl_disconnect 
iabbrev qtcl_get_widget_data	qtcl_get_data 
iabbrev qtcl_get_widget_property	qtcl_get_property 
iabbrev qtcl_operate_widget	qtcl_operate 
iabbrev qtcl_remove_widget_property	qtcl_remove_property 
iabbrev qtcl_set_widget_property	qtcl_set_property 
iabbrev qv	print_vars -print -value -regexp 
iabbrev ra	report_attributes -application -nosplit 
iabbrev rc	remove_from_collection 
iabbrev rct	report_clock_timing -type latency -net -physical -verbose 
iabbrev report_aocvm	report_ocvm {-type} {aocvm} 
iabbrev rt	report_timing -significant_digits 4 -input_pins -capacitance -nets -attributes -delay_type max -transition_time -physical -path_type full_clock 
iabbrev rtmax	report_timing -sort_by slack -significant_digits 4 -nosplit -transition_time -nets -input_pins -capacitance -delay_type max -attributes -physical 
iabbrev rtmin	report_timing -sort_by slack -significant_digits 4 -nosplit -transition_time -nets -input_pins -capacitance -delay_type min -attributes -physical 
iabbrev s_cell	::gui::select_cell 
iabbrev s_net	::gui::select_net 
iabbrev s_port	::gui::select_port 
iabbrev s_terminal	::gui::select_terminal 
iabbrev sa	set_attribute 
iabbrev sc	sizeof_collection 
iabbrev sg	start_gui 
iabbrev st	rdt_list_steps -print 
iabbrev stages	als_stages 
iabbrev steps	als_steps 
iabbrev zs	::gui::zoom -selection 
