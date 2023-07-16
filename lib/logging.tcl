package provide logging 0.1
package require ansifmt
package require formats

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

    variable process
    variable start_time [clock milliseconds]

    proc elapsed {} {
        variable start_time
        set time [clock milliseconds]
        return [expr {($time - $start_time) / 1000.0}]
    }

    proc prefix {} {
        variable process
        variable start_time
        set pfx ""
        if {[info exists start_time]} {
            set et [fmt duration [elapsed]]
            set nspace [expr {6 - [string length $et]}]
            if {$nspace > 0} {
                set space [string repeat " " $nspace]
            } else {
                set space ""
            }
            append pfx "\[$space[ansi::fmt -fg green]$et[ansi::fmt -reset]\] "
        }
        if {[info exists process]} {
        append pfx "[ansi::fmt -fg yellow]$process[ansi::fmt -reset] "
        }
        
        return $pfx
    }

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

    proc set_env_config {} {
        variable start_time
        variable verbose
        msg -debug "propagating log config to environment"
        set ::env(ME_LOG_START_CLOCK) $start_time
        set ::env(ME_LOG_VERBOSE) $verbose
    } 

    proc configure args {
        variable verbose
        variable lvl_verb
        variable process
        while {![lempty $args]} {
            set flag [lshift args]
            switch -- $flag {
                -verbose {
                    incr verbose
                }
                -quiet {
                    incr verbose -1
                }
                -level {
                    set verbose $lvl_verb([lshift args])
                }
                -process {
                    set process [lshift args]
                }
                -propagate {
                    set_env_config
                }
                default {
                    error "unrecognized option $flag"
                }
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

        ansi::with_out stderr {
            set msg [ansi::wrap {*}$args]
            set fmt_proc "fmt_$level"
            puts stderr [prefix][$fmt_proc $msg]
        }
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
