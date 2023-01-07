package provide logging 0.1
package require ansifmt

namespace eval logging {
    namespace export msg

    variable verbose 0

    variable lvl_verb
    set lvl_verb(debug) 1
    set lvl_verb(info) 0
    set lvl_verb(warn) -1
    set lvl_verb(error) -2

    variable lvl_alias
    set lvl_alias(err) error

    proc fmt_debug {msg} {
        return "[ansi::fmt -dim]DBG: $msg[ansi::fmt -reset]"
    }
    proc fmt_info {msg} {
        return "[ansi::fmt -bold -fg blue]MSG:[ansi::fmt -fg default] $msg[ansi::fmt -reset]"
    }
    proc fmt_warn {msg} {
        return "[ansi::fmt -bold -fg yellow]WRN: $msg[ansi::fmt -reset]"
    }
    proc fmt_error {msg} {
        return "[ansi::fmt -bold -fg red]ERR: $msg[ansi::fmt -reset]"
    }

    proc configure {flag {arg ""}} {
        variable verbose
        variable lvl_verb
        switch -- $flag {
            -verbose {
                set verbose 1
            }
            -quiet {
                set verbose -1
            }
            -level {
                set verbose $lvl_verb($arg)
            }
            default {
                error "unrecognized option $flag"
            }
        }
    }

    proc msg {code args} {
        variable lvl_alias
        variable lvl_verb
        variable verbose

        set level info
        set fmt ""
        # check for a level argument
        switch -glob -- $code {
            -success {
                set fmt [ansi::fmt -fg green]
            }
            -result {
                set fmt [ansi::fmt -reset]
            }
            -* {
                set level [string range $code 1 end]
            }
            default {
                set args [linsert $args 0 $code]
            }
        }

        set msg "$fmt[join $args]"

        if {[info exists lvl_alias($level)]} {
            set level $lvl_alias($level)
        }

        if {![info exists lvl_verb($level)]} {
            return -code error -errorcode bad-level "invalid logging level $level"
        }

        if {$lvl_verb($level) <= $verbose} {
            set fmt_proc "fmt_$level"
            puts stderr [$fmt_proc $msg]
        }
    }
}

namespace import logging::msg
