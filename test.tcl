#!/bin/sh
# \
exec tclsh "$0" "$@"
#TODO: license

package require Tcl 8.4

variable width 20
variable height 4

# Open serial port and set parameters
# @parm port    Device (for example, /dev/ttyUSB0)
# @return Device identifier
proc connect {device} {
    set f [open $device {RDWR NOCTTY}]
    set baud 9600
    fconfigure $f \
        -mode $baud,n,8,1 \
        -buffering none \
        -translation binary \
        -encoding binary \
        -ttycontrol {RTS 1 DTR 1}
    return $f
}

# Send a command to the device
# @param fd     Device identifier
# @param format Arguments format (as for [binary format])
# @param args   Arguments
proc command {fd format args} {
    puts -nonewline $fd [eval [list binary format c$format 0xfe] $args]
    after 20
}

# Enable or disable backlight
# @param fd     Device identifier
# @param mode   'on' or 'off'
proc backlight {fd mode} {
    if {$mode} {
        command $fd ac B 0
    } else {
        command $fd a F
    }
}

# Fill screen by spaces
# @param fd     Device identifier
proc clrscr {fd} {
    variable width
    variable height
    for {set i 0} {$i < $height} {incr i} {
        writeLine $fd $i [string repeat " " $width]
    }
}

# Close communication channel
# @param fd     Device identifier
proc destroy {fd} {
    close $fd
}

# Configure display contrast
# @param fd     Device identifier
# @param level  Contrast level (0 (most contrast) to 255 (unreadable))
proc contrast {fd level} {
    command $fd ac P $level
}

# Write text into specified line
# @param fd     Device identifier
# @param line   Line number (starting from 0)
# @param str    String to write
proc writeLine {fd line str} {
    variable width
    set len [string length $str]
    if {$len > $width} {
        set str [string range $str 0 [expr {$width - 1}]]
    } else {
        append str [string repeat " " [expr {$width - $len}]]
    }
    command $fd acca* \
        G 1 [expr {$line+1}] $str
}

# Define a custom character
# @param fd     Device identifier
# @param char   Character number (0..7 are available)
# @param d_i    Bit mask
proc customChar {fd char d0 d1 d2 d3 d4 d5 d6 d7} {
    command $fd acc8 \
        N $char [list $d0 $d1 $d2 $d3 $d4 $d5 $d6 $d7]
}

############################################################################
# TEST
############################################################################

set f [connect /dev/ttyUSB0]
#backlight $f on
contrast $f 0
#clrscr $f

customChar $f 0 \
    2 12 22 22 12 33 07 05

writeLine $f 0 [clock format [clock seconds] -format "%H:%M:%S %d.%m.%Y"]
writeLine $f 1 "abcd"
writeLine $f 2 "abcd"
writeLine $f 3 "\x00\x00"

after 100
flush $f
destroy $f
exit
