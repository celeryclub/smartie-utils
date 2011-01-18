#!/bin/sh
# \
exec tclsh "$0" "$@"
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

lappend auto_path [file join [file dirname [info script]] lib]

package require smartie
package require cmdline

namespace import ::smartie::*

set options {
    {tty.arg        ""  "TTY for connecting to the device"}
    {contrast.arg   ""  "Contrast level (0 - most contrast, 255 - less contrast)"}
    {backlight.arg  ""  "Backlight (0 - off, 1 - on)"}
}
set usage ": $argv0 \[options\] -tty <tty>\n    Set LCD screen contrast and configure backlight\noptions:"
if {[catch {
    array set params [::cmdline::getoptions argv $options $usage]
} err]} {
    puts stderr $err
    exit 1
}
if {$params(tty) eq "" || [llength $argv] != 0} {
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

