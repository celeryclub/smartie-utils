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
set usage ": $argv0 -tty <tty> \[filename\]\n    Write text to LCD screen\noptions:"
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

set fname [lindex $argv 0]

if {$fname ne ""} {
    set f [open $fname r]
} else {
    set f stdin
}
set lines [split [read $f] \n]
if {$fname ne ""} {
    close $f
}

set lcd [connect $params(tty) $params(width) $params(height)]
for {set i 0} {$i < $params(height)} {incr i} {
    writeLine $lcd $i [lindex $lines $i]
}
destroy $lcd

