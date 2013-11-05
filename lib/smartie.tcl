##############################################################################
# Copyright (c)2011 Alexander Galanin
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
##############################################################################

package require Tcl 8.4

package provide smartie 1.0

namespace eval smartie {

namespace export \
    connect \
    backlight \
    clrscr \
    destroy \
    contrast \
    writeLine \
    customChar

# Open serial port and set parameters
# @param port   Device (for example, /dev/ttyUSB0)
# @param width  Display width
# @param height Display height
# @return Device identifier
proc connect {device {width 20} {height 4}} {
    if {$::tcl_platform(platform) == "windows"} {
        set f [open \\\\.\\$device RDWR]
    } else {
        set f [open $device {RDWR NOCTTY}]
    }
    set baud 9600
    fconfigure $f \
        -mode $baud,n,8,1 \
        -buffering none \
        -translation binary \
        -encoding binary \
        -ttycontrol {RTS 1 DTR 1}
    return [list $f $width $height]
}

# Send a command to the device
# @param fd     Device identifier
# @param format Arguments format (as for [binary format])
# @param args   Arguments
proc command {fd format args} {
    set chan [lindex $fd 0]
    puts -nonewline $chan [eval [list binary format c$format 0xfe] $args]
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
    lassign $fd chan width height
    for {set i 0} {$i < $height} {incr i} {
        writeLine $fd $i [string repeat " " $width]
    }
}

# Close communication channel
# @param fd     Device identifier
proc destroy {fd} {
    after 100
    close [lindex $fd 0]
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
    set width [lindex $fd 1]
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

}
