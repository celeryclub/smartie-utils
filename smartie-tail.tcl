#!/bin/sh
# \
exec tclsh "$0" "$@"
#TODO: license

lappend auto_path [file join [file dirname [info script]] lib]

package require smartie
package require cmdline

namespace import ::smartie::*

set options {
    {tty.arg    ""  "TTY for connecting to the device"}
    {width.arg  20  "Display width"}
    {height.arg 4   "Display height"}
}
set usage ": $argv0 -tty <tty>\n    Tail stdin to LCD screen\noptions:"
if {[catch {
    array set params [::cmdline::getoptions argv $options $usage]
} err]} {
    puts stderr $err
    exit 1
}
if {$params(tty) eq "" || [llength $argv] > 1} {
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}

set height $params(height)
set lcd [connect $params(tty) $params(width) $height]

set lines [lrepeat $height {}]
while {![eof stdin]} {
    gets stdin line
    lappend lines $line
    set lines [lrange $lines 1 end]
    for {set i 0} {$i < $height} {incr i} {
        writeLine $lcd $i [lindex $lines $i]
    }
}

destroy $lcd

