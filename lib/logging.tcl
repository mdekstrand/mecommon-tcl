package provide logging 0.1
package require ansifmt

namespace eval logging {
    namespace export msg

    variable verbose 0

    variable lvl_verb
    set lvl_verb(trace) 2
    set lvl_verb(debug) 1
    set lvl_verb(info) 0
    set lvl_verb(warn) -1
    set lvl_verb(error) -2

    variable lvl_alias
    set lvl_alias(err) error

    proc fmt_trace {msg} {
        return "[ansi::fmt -dim]TRC:[ansi::fmt -reset] $msg"
    }
    proc fmt_debug {msg} {
        return "[ansi::fmt -fg cyan]DBG: $msg[ansi::fmt -reset]"
    }
    proc fmt_info {msg} {
        return "[ansi::fmt -bold -fg blue]MSG:[ansi::fmt -reset] $msg[ansi::fmt -reset]"
    }
    proc fmt_warn {msg} {
        return "[ansi::fmt -bold -fg yellow]WRN: $msg[ansi::fmt -reset]"
    }
    proc fmt_error {msg} {
        return "[ansi::fmt -bold -fg red]ERR: $msg[ansi::fmt -reset]"
    }

    proc verb_level {{v current}} {
        variable lvl_verb
        variable verbose
        if {[string equal $v current]} {
            set v $verbose
        }
        foreach name [array names lvl_verb] {
            if {$lvl_verb($name) == $v} {
                return $name
            }
        }

        return "unknown"
    }

    proc configure {flag {arg ""}} {
        variable verbose
        variable lvl_verb
        switch -- $flag {
            -verbose {
                incr verbose
            }
            -quiet {
                incr verbose -1
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
        set tag ""
        # check for a level argument
        switch -glob -- $code {
            -success {
                lunshift args -bold -fg green
            }
            -result {
            }
            -* {
                set level [string range $code 1 end]
            }
            default {
                lunshift args $code
            }
        }

        if {[info exists lvl_alias($level)]} {
            set level $lvl_alias($level)
        }

        if {![info exists lvl_verb($level)]} {
            return -code error -errorcode bad-level "invalid logging level $level"
        }

        if {$lvl_verb($level) > $verbose} {
            return
        }

        set msg ""
        set codes {}
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
                default {
                    if {$msg ne ""} {
                        append msg " "
                    }
                    if {![lempty $codes]} {
                        append msg [ansi::fmt {*}$codes]
                        set codes {}
                    }
                    append msg $arg
                }
            }
        }

        set fmt_proc "fmt_$level"
        puts stderr [$fmt_proc $msg]
    }

    proc ns_msg {ns {tag ""}} {
        if {$tag eq ""} {
            set tag $ns
        }
        set "::${ns}::_log_tag" "$tag:"

        uplevel #0 [list proc "::${ns}::msg" {code args} {
            variable _log_tag
            set dargs [list $_log_tag]
            if {[string match -* $code]} {
                set dargs [linsert $dargs 0 $code]
            } else {
                lappend dargs $code
            }
            lappend dargs {*}$args
            ::logging::msg {*}$dargs
        }]
    }
}

namespace import logging::msg
