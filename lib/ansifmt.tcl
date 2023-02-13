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
    variable enabled 1

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

# query whether a handle is a tty
proc ::ansi::isatty {handle} {
    if {[info exists ::tcl_platform(engine)] && $::tcl_platform(engine) eq "Jim"} {
        # Jim - use aio
        return [$handle isatty]
    } else {
        # Tcl - inspect fconfigure, terminals have -mode
        set attrs [fconfigure $handle]
        return [dict exists $attrs -mode]
    }
}

proc ::ansi::default_term {handle} {
    set enabled [isatty $handle]
}

proc ::ansi::color_enabled {{h ""}} {
    variable enabled

    if {[info exists ::env(NO_COLOR)] && $::env(NO_COLOR) ne ""} {
        return 0
    } elseif {$h ne ""} {
        return [isatty $h]
    } else {
        # color enabled and we aren't checking a specific stream
        return $enabled
    }
}

# evaluate body assuming ansi is going to $out
proc ::ansi::with_out {out body} {
    variable enabled
    set old $enabled
    set enabled [isatty $out]
    set status [catch {
        uplevel 1 $body
    } rv ropts]
    set enabled $old
    return {*}$ropts $rv
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

    if {[color_enabled]} {
        set fmt [join $codes ";"]
        return "\33\[${fmt}m"
    } else {
        return ""
    }
}

# wrap things in ANSI codes, followed by reset
proc ansi::wrap args {
    set formatted ""
    set codes {}
    set final_reset 1
    while {![lempty $args]} {
        set arg [lshift args]
        switch -- "$arg" {
            -fg -
            -bg {
                lappend codes $arg [lshift args]
            }
            -bold -
            -dim -
            -reset {
                lappend codes $arg
            }
            -no-reset {
                set final_reset 0
            }
            default {
                if {$formatted ne ""} {
                    append formatted " "
                }
                if {![lempty $codes]} {
                    append formatted [ansi::fmt {*}$codes]
                    set codes {}
                }
                append formatted $arg
            }
        }
    }
    if {$final_reset} {
        append formatted [ansi::fmt -reset]
    }
    return $formatted
}
