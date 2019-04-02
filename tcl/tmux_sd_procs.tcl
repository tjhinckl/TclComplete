proc annotate_bboxes_from_file {file_name {colors yellow}} {
    set num_colors [llength $colors]

    set float_re  {\d+\.?\d*}
    set point_re  "${float_re} +${float_re}"
    # set bbox_re   "$point_re\\s+$point_re"

    set lines [split [file::read_file $file_name] "\n"]
    set count 0
    foreach line $lines {
        set points [lsearch -regexp -all -inline $line $point_re]
        # The colors argument can be a list of colors.  The first bbox on each line 
        #  will use the first color.  The second bbox will use the second color, etc.
        #  If there are more bboxes than colors, then the color cycle will restart.
        set num_points [llength $points]
        if {$num_points == 0} {
            continue
        }
        incr count
        set color_index [expr {$count % $num_colors}]
        set color [lindex $colors $color_index]

        if {$num_points==1} {
            echo "Point: $points ($color)"
            gui_add_annotation -type symbol -symbol_type x -symbol_size 5 -color $color $points
        } elseif {$num_points==2} {
            echo "Bbox: $points ($color)"
            gui_add_annotation -type rect -color $color $points
        } else {
            echo "Polygon: $points ($color)"
            gui_add_annotation -type polygon -color $color $points
        }
    }
}
