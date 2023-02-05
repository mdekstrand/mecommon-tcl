# uri.tcl -
# utilities for HTTP, etc. URIs.
# very limited — lots of URI features not yet supported.

package provide uri 0.1

namespace eval uri {
    set abs_re {^(?:(https?|s?ftp)?://([^:/]+)(:\d+)?)?(/[^?]*)(?.*)}
}

proc uri::parse_abs {uri} {
    if {[regexp $abs_re $uri -> scheme host port path query]} {
    }
}

proc uri::encode {uri} {
}

proc uri {cmd args} {
    set commands [list encode]
    if {$cmd in $commands} {
        return [uplevel 1 uri::$cmd {*}$args]
    } else {
        error "unknown uri subcommand $cmd"
    }
}
