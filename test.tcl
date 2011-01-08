#!/bin/sh
# \
exec tclsh "$0" "$@"
#TODO: license

package require Tcl 8.4

variable width 20
variable height 4

# connect --
#
#   Open serial port and set parameters
#
# Arguments:
#   port    Device (for example, /dev/ttyUSB0)
#
# Return:
#   Channel identifier

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

# command --
#
#   Send 'text' to device with command prefix
#
# Arguments:
#   fd      Channel
#   text    Text to send

proc command {fd text} {
    puts -nonewline $fd [binary format ca* \
        0xfe $text \
    ]
    after 20
}

# backlight --
#
#   Enable or disable backlight

proc backlight {fd mode} {
    if {$mode} {
        command $fd "B\x00"
    } else {
        command $fd F
    }
}

# clrscr --
#
#   Fill screen by spaces

proc clrscr {fd} {
    variable width
    variable height
    for {set i 0} {$i < $height} {incr i} {
        writeLine $fd $i [string repeat " " $width]
    }
}

# destroy --
#
#   Close communication channel

proc destroy {fd} {
    close $fd
}

# contrast --
#
#   Configure display contrast (0 (most contrast) to 255 (unreadable))

proc contrast {fd level} {
    command $fd [binary format ac P $level]
}

# writeLine --
#
#   Write text into specified line
#
# Arguments:
#   fd      Channel
#   line    Line number (starting from 0)
#   str     String to write

proc writeLine {fd line str} {
    variable width
    set len [string length $str]
    if {$len > $width} {
        set str [string range $str 0 [expr {$width - 1}]]
    } else {
        append str [string repeat " " [expr {$width - $len}]]
    }
    command $fd [binary format acca* \
        G 1 [expr {$line+1}] $str \
    ]
}

# customChar --
#
#   Define a custom character
#
# Arguments:
#   fd      Channel
#   char    Character number (0..7 are available)
#   d_i     Bitmask

proc customChar {fd char d0 d1 d2 d3 d4 d5 d6 d7} {
    command $fd [binary format acc8 \
        N $char [list $d0 $d1 $d2 $d3 $d4 $d5 $d6 $d7] \
    ]
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
