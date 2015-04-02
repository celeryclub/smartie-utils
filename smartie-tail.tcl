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
    {tty.arg    ""  "TTY for connecting to the device"}
    {sleep.arg  0   "Sleep specified number of milliseconds between flushes"}
    {width.arg  20  "Display width"}
    {height.arg 4   "Display height"}
    {buffer.arg 1   "Flush output every n lines"}
}
set usage ": $argv0 -tty <tty> \[filename\\n    Tail stdin or file to LCD screen\noptions:"
if {[catch {
    array set params [::cmdline::getoptions argv $options $usage]
} err]} {
    puts stderr $err
    exit 1
}
if {$params(tty) eq "" || [llength $argv] > 2} {
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}
set fileName [lindex $argv 0]

if {$fileName ne ""} {
    set in [open $fileName r]
} else {
    set in stdin
}

set height $params(height)
set lcd [connect $params(tty) $params(width) $height]

set lines {}
for {set i 0} {$i < $height} {incr i} {
    lappend lines {}
}

set buffer $params(buffer)
set buffSize 0
while {![eof $in]} {
    gets $in line
    lappend lines $line
    set lines [lrange $lines 1 end]
    incr buffSize
    if {$buffSize == $buffer} {
        set buffSize 0
        for {set i 0} {$i < $height} {incr i} {
            writeLine $lcd $i [lindex $lines $i]
        }
    }
    if {$params(sleep) > 0} {
        after $params(sleep)
    }
}

destroy $lcd
if {$in ne "stdin"} {
    close $in
}
