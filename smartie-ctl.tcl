#!/bin/sh
# \
exec tclsh "$0" "$@"
#TODO: license

lappend auto_path [file join [file dirname [info script]] lib]

package require smartie
package require cmdline

namespace import ::smartie::*

set options {
    {tty.arg        ""  "TTY for connecting to the device"}
    {contrast.arg   ""  "Contrast level (0 - most contrast, 255 - less contrast)"}
    {backlight.arg  ""  "Backlight (0 - off, 1 - on)"}
}
set usage ": $argv0 \[options\] -tty <tty>\noptions:"
if {[catch {
    array set params [::cmdline::getoptions argv $options $usage]
} err]} {
    puts stderr $err
    exit 1
}
if {$params(tty) eq ""} {
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}

set f [connect $params(tty)]
if {$params(backlight) ne ""} {
    backlight $f $params(backlight)
}
if {$params(contrast) ne ""} {
    contrast $f $params(contrast)
}
destroy $f

