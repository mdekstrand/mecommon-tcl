# ansifmt.tcl --
#
#   This package provides quick access to basic ANSI terminal formatting codes.
#
# Copyright (c) 2023 Michael D. Ekstrand
# Provided under the MIT license, see LICENSE for details.
package provide ansifmt 0.1
package require missing

namespace eval ansi {
    variable colors {
        black red green yellow
        blue magenta cyan white
    }

    variable fg_codes
    variable bg_codes
    set fg_codes(default) 39
    set bg_codes(default) 49
    for {set i 0} {$i < [llength $colors]} {incr i} {
        set c [lindex $colors $i]
        set fg_codes($c) [expr {$i + 30}]
        set bg_codes($c) [expr {$i + 40}]
    }
}

# ::ansi::fmt --
#
#   Compute an ANSI terminal escape sequence from the specified format.
#
# Results:
#   A string containing ANSI terminal escapes for the specified attributes.
proc ::ansi::fmt {args} {
    variable fg_codes
    variable bg_codes

    set codes {}
    set nargs [llength $args]
    if {$nargs <= 0} {
        return ""
    }
    while {![lempty $args]} {
        set arg [lshift args]
        switch -- $arg {
            -bold {
                lappend codes 1
            }
            -dim {
                lappend codes 2
            }
            -ul {
                lappend codes 4
            }
            -fg {
                lappend codes $fg_codes([lshift args])
            }
            -bg {
                lappend codes $bg_codes([lshift args])
            }
            -reset {
                lappend codes 0
            }
            default {
                error "invalid option $arg"
            }
        }
    }

    set fmt [join $codes ";"]
    return "\33\[${fmt}m"
}
