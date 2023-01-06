package provide logging 0.1
package require ansifmt

namespace eval logging {
    variable verbose 0

    variable lvl_verb
    set lvl_verb(debug) 1
    set lvl_verb(info) 0
    set lvl_verb(warn) -1
    set lvl_verb(error) -2

    variable lvl_alias
    set lvl_alias(err) error

    variable lvl_format
    set lvl_format(debug) {[ansi::fmt -dim]DBG: $msg[ansi::fmt -reset]}
    set lvl_format(info) {[ansi::fmt -bold -fg blue]MSG:[ansi::fmt -fg default] $msg[ansi::fmt -reset]}
    set lvl_format(warn) {[ansi::fmt -bold -fg yellow]WRN: $msg[ansi::fmt -reset]}
    set lvl_format(error) {[ansi::fmt -bold -fg red]ERR: $msg[ansi::fmt -reset]}
}

proc msg {args} {
    set level info
    set msg [lindex $args 0]
    # check for a level argument
    if {[regexp {^-([a-z]+)} $msg -> flag]} {
        set level $flag
        set msg [lindex $args 1]
    }

    if {[info exists ::logging::lvl_alias($level)]} {
        set level $::logging::lvl_alias($level)
    }

    if {![info exists ::logging::lvl_verb($level)]} {
        return -code error -errorcode bad-level "invalid logging level $level"
    }

    if {$::logging::verbose >= $::logging::lvl_verb($level)} {
        set fmt [subst $::logging::lvl_format($level)]
        puts stderr $fmt
    }
}
