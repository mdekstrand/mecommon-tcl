# meuri.tcl -
# utilities for HTTP, etc. URIs.
# very limited — lots of URI features not yet supported.

package provide meuri 0.1

namespace eval uri {
    set abs_re {^(?:(https?|s?ftp)?://([^:/]+)(:\d+)?)?(/[^?]*)(?.*)}
}

proc uri::parse_abs {uri} {
    if {[regexp $abs_re $uri -> scheme host port path query]} {
    }
}

proc uri::encode {data} {
    set n [string length $data]
    set string ""
    for {set i 0} {$i < $n} {incr i} {
        set char [string index $data $i]
        if {[string is alnum $char] || $char in {- _ . ~}} {
            append string $char
        } elseif {$char eq " "} {
            append string %20
        } else {
            scan char %c cno
            append string [format "%%%02d" $cno]
        }
    }
    return $string
}

proc uri {cmd args} {
    set commands [list encode]
    if {$cmd in $commands} {
        return [uri::$cmd {*}$args]
    } else {
        error "unknown uri subcommand $cmd"
    }
}
