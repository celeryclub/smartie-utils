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
    customChar \
    loadCyrillicChars \
    convertCyrillicText

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

# Define custom characters for displaying Cyrillic text
proc loadCyrillicChars {fd} {
    customChar $fd 0 0x12 0x12 0x12 0x12 0x12 0x12 0x1f 1
    customChar $fd 1 0x15 0x15 0x15 0x15 0x15 0x15 0x1f 0
    customChar $fd 2 0x11 0x11 0x11 0x19 0x15 0x15 0x19 0
    customChar $fd 3 0x1f 0x11 0x11 0x11 0x11 0x11 0x11 0
    customChar $fd 4 0x15 0x15 0x15 0xe 0x15 0x15 0x15 0
    customChar $fd 5 0xf 0x11 0x11 0xf 0x11 0x11 0x11 0
    customChar $fd 6 0x1f 0x10 0x10 0x1e 0x11 0x11 0x1e 0
    customChar $fd 7 0x12 0x15 0x15 0x1d 0x15 0x15 0x12 0
}

# Replace chars in Cyrillic text to be viewed using Smartie
proc convertCyrillicText {text} {
    string map {
        \u0419   \xf5
        \u0439   \xf5
        \u0426   \x00
        \u0446   \x00
        \u0423   Y
        \u0443   y
        \u041A   K
        \u043A   k
        \u0415   E
        \u0435   e
        \u041D   H
        \u043D   H
        \u0413   \xa2
        \u0433   \xa2
        \u0428   \x01
        \u0448   \x01
        \u0429   \x01
        \u0449   \x01
        \u0417   3
        \u0437   3
        \u0425   X
        \u0445   x
        \u042A   b
        \u044A   b
        \u0424   \xec
        \u0444   \xec
        \u042B   \x02
        \u044B   \x02
        \u0412   B
        \u0432   B
        \u0410   A
        \u0430   a
        \u041F   \x03
        \u043F   \x03
        \u0420   P
        \u0440   p
        \u041E   O
        \u043E   o
        \u041B   \xca
        \u043B   \xca
        \u0414   D
        \u0434   d
        \u0416   \x04
        \u0436   \x04
        \u042D   \xd6
        \u044D   \xae
        \u042F   \x05
        \u044F   \x05
        \u0427   \xd1
        \u0447   \xd1
        \u0421   C
        \u0441   c
        \u041C   M
        \u043C   M
        \u0418   \xe4
        \u0438   \xe4
        \u0422   T
        \u0442   T
        \u042C   b
        \u044C   b
        \u0411   \x06
        \u0431   \x06
        \u042E   \x07
        \u044E   \x07
        \u0401   E
        \u0451   e
        \\  \xa4
        ~   \xf3
    } $text
}

}
