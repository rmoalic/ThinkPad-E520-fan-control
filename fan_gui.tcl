#!/usr/bin/env tclsh

package require Tk
proc uniqkey { } {
    set key   [ expr { pow(2,31) + [ clock clicks ] } ]
    set key   [ string range $key end-8 end-3 ]
    set key   [ clock seconds ]$key
    return $key
}

proc sleep { ms } {
    set uniq [ uniqkey ]
    set ::__sleep__tmp__$uniq 0
    after $ms set ::__sleep__tmp__$uniq 1
    vwait ::__sleep__tmp__$uniq
    unset ::__sleep__tmp__$uniq
}

set ec_fan_offset 0x93

while { [catch {set ec [open "/sys/kernel/debug/ec/ec0/io" r+]} result] } {
    if { $errorCode eq "POSIX EACCES {permission denied}" } {
        set answer [tk_messageBox -message "This application can't run without root access" -detail $result -type ok]
    } elseif { $errorCode eq "POSIX ENOENT {no such file or directory}" } {
        set answer [tk_messageBox -message "The ec_sys module needs to be loaded\ndo you want to load it ?" -detail $result -type yesno]
    } else {
        puts $result
        puts $errorInfo
        exit 1
    }
    if { $answer eq "no" || $answer eq "ok"} {
        exit 1
    } else {
        exec modprobe ec_sys write_support=1
    }
}
fconfigure $ec -translation binary

set thermal [open "/sys/class/thermal/thermal_zone1/temp" r]

wm title . "Fan gui"
wm minsize . 140 260
#TODO: handle graph resize
wm maxsize . 140 260
wm resizable . true false
wm protocol . WM_DELETE_WINDOW { exit }

label .l_fan_actual -textvariable  f_fan_actual_val
label .l_fan_rpm -textvariable  f_fan_rpm
label .l_package_temp -textvariable f_package_temp

set plot_last_x 0
set plot_last_y 0
set plot_height 100
set plot_width 150
canvas .c_fan_graph -width $plot_width -height $plot_height -background yellow -xscrollincrement 1

scale .s_fan_actual -from 255 -to 0 -resolution 1 -showvalue false -orient horizontal -variable fan_actual -state disabled
scale .s_fan_select -label "selected fan speed" -command setfanspeed -from 255 -to 0 -resolution 1 -showvalue true -orient horizontal -variable fan_selected
checkbutton .cb_fan_auto -text "Auto" -onvalue "auto" -offvalue "manual" -command setfanmode_from_button -variable fan_auto_button

pack .l_fan_actual
pack .l_fan_rpm .l_package_temp
pack .c_fan_graph -fill x
pack .s_fan_actual -fill x
pack .s_fan_select -fill x
pack .cb_fan_auto

proc setfanspeed { speed } {
    global ec
    global ec_fan_offset
    set out [binary format cucu 0x14 $speed]

    seek $ec $ec_fan_offset

    puts -nonewline $ec $out

    update_fan_mode_ui "manual"
}

proc setfanmode { mode } {
    global ec
    global ec_fan_offset

    if { $mode eq "auto" } {
        set out [binary format cu 0x04]
    } elseif { $mode eq "manual" } {
        set out [binary format cu 0x14]
    } else {
        puts ERR
    }

    seek $ec $ec_fan_offset

    puts -nonewline $ec $out

    update_fan_mode_ui $mode
}

proc setfanmode_from_button {} {
    global fan_auto_button

    setfanmode $fan_auto_button
}

proc update_fan_mode_ui { new_mode } {
    if { $new_mode eq "auto" } {
        #.s_fan_select configure -state disabled
        .cb_fan_auto select
    } elseif { $new_mode eq "manual" } {
        #.s_fan_select configure -state normal
        .cb_fan_auto deselect
    } else {
        puts "ERR $new_mode"
    }
}

set prev_fan_mode 0
set prev_temp 0
set gc_counter 0

#TODO: update data in coroutine instead of ui thread
while {1} {

    seek $ec $ec_fan_offset

    set vals [read $ec 3]

    binary scan $vals cucucu fan_mode fan_selected fan_actual
    #set fan_selected_inv [expr {255 - $fan_selected}]
    set fan_actual_inv [expr {255 - $fan_actual}]
    set fan_rpm [expr {$fan_actual_inv * 21}]
    set f_fan_actual_val "current fan speed: $fan_actual"
    set f_fan_rpm "$fan_rpm rpm"


    if {$fan_mode != $prev_fan_mode} {
        if { [expr { $fan_mode & 0x10 }] > 0 } {
            update_fan_mode_ui "manual"
        } else {
            update_fan_mode_ui "auto"
        }
        set prev_fan_mode $fan_mode
    }

    seek $thermal 0
    set package_temp [expr {[read -nonewline $thermal] / 1000}]
    set f_package_temp "${package_temp}ºC"

    # ////// canvas update
    set new_x [expr {$plot_last_x + 1}]
    set new_y [expr {ceil(($fan_actual / 255.0) * $plot_height)}]
    .c_fan_graph create line $plot_last_x $plot_last_y $new_x $new_y -tags gline
    .c_fan_graph create line $plot_last_x [expr {$plot_height - $prev_temp}] $new_x [expr {$plot_height - $package_temp}] -fill red -tags gline

    set plot_last_y $new_y
    set prev_temp $package_temp

    if { $plot_last_x > [winfo width .c_fan_graph] } {
        if { $gc_counter > 50 } {
            .c_fan_graph addtag dtag enclosed 0 0 -100 $plot_height
            .c_fan_graph delete dtag
            set gc_counter 0
        }
        .c_fan_graph move gline -1 0
    } else {
        set plot_last_x $new_x
    }
    incr gc_counter
    # ////// end canvas update

    sleep 500
}
