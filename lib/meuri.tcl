# meuri.tcl -
# utilities for HTTP, etc. URIs.

package provide meuri 0.1
package require missing
package require logging

namespace eval uri {
    variable re_scheme {^([:alpha:][a-zA-Z0-9+.-]*):}
    variable re_auth {(?:([^@/]+)@)?([^:/@]+)(?::(\d+))?}
    variable re_path {(/[^?#]*)}
    variable re_query {(\?[^#]*)}
    variable re_frag {(#.*)}
    variable re_absolute "$re_scheme//$re_auth$re_path?$re_query?$re_frag?$"
    variable re_schemerel "^://$re_auth$re_path?$re_query?$re_frag?$"
    variable re_rel "(\[^?#\]*)$re_query?$re_frag?$"
    variable uri_parts [list scheme login host port path query fragment]
    variable commands [list parse unparse encode]
}

proc uri::parse {uri} {
    variable re_absolute
    variable re_schemerel
    variable re_rel
    variable uri_parts

    if {[regexp $re_absolute $uri -> x(scheme) x(login) x(host) x(port) x(path) x(query) x(fragment)]} {
        msg -trace "absolute: $uri"
    } elseif {[regexp $re_schemerel $uri -> x(login) x(host) x(port) x(path) x(query) x(fragment)]} {
        msg -trace "absolute: $uri"
    } elseif {[regexp $re_rel $uri -> x(path) x(query) x(fragment)]} {
        msg -trace "relative: $uri"
    } else {
        error "unparseable URI"
    }
    foreach part $uri_parts {
        if {![info exists x($part)]} {
            set x($part) ""
        }
    }

    return [array get x]
}

proc uri::part {parts name} {
    upvar $name var
    if {[dict exists $parts $name]} {
        set var [dict get $parts $name]
        return 1
    } else {
        return 0
    }
}

proc uri::unparse {parts} {
    set uri ""
    if {[part $parts scheme]} {
        set uri $scheme
    }
    if {[part $parts host]} {
        append uri ://
        if {[part $parts login]} {
            append uri "$login@"
        }
        append uri $host
        if {[part $parts port]} {
            append uri ":$port"
        }
    }
    if {[part $parts path]} {
        append uri $path
    }
    if {[part $parts query]} {
        append uri $query
    }
    if {[part $parts fragment]} {
        append uri $fragment
    }
    return $uri
}

proc uri::encode {data} {
    set n [string length $data]
    set string ""
    for {set i 0} {$i < $n} {incr i} {
        set char [string index $data $i]
        if {[string is alnum $char] || $char in {- _ . ~}} {
            append string $char
        } else {
            set cno [scan $char %c]
            append string [format "%%%02x" $cno]
        }
    }
    return $string
}

proc uri::is_absolute {uri} {
    variable re_scheme
    return [regexp $re_scheme $uri]
}

proc uri {cmd args} {
    if {$cmd in $::uri::commands} {
        return [uri::$cmd {*}$args]
    } elseif {$cmd eq "is"} {
        set cmd [lshift args]
        if {[exists -command "uri::is_$cmd"]} {
            return [uri::is_$cmd {*}$args]
        } else {
            error "unknown uri predicate $cmd"
        }
    } else {
        error "unknown uri subcommand $cmd"
    }
}
