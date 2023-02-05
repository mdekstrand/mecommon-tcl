# meuri.tcl -
# utilities for HTTP, etc. URIs.
# this is probably buggy around edge cases

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
    variable commands [list parse unparse encode resolve]
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
        return [expr {$var ne ""}]
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

proc uri::resolve {base uri} {
    if {![is_absolute $base]} {
        error "cannot resolve against relative URI $base"
    }
    if {[is_absolute $uri]} {
        return $uri
    }
    set bp [parse $base]
    set up [parse $uri]
    if {[part $up host]} {
        return "[dict get $bp scheme]$uri"
    }

    # at this point, uri does not have scheme or host. Let's start building.
    array set new $bp
    if {[part $up path]} {
        # we have a path. split it so we can start working.
        set parts [split $new(path) /]
        set nparts [split $path /]

        # split will make last part of parts {}, for ending /, or a filename
        # either way, dropping last element will prepare us for resolution
        set parts [lrange $parts 0 end-1]

        if {[lindex $nparts 0] eq ""} {
            # new path is absolute - we're done
            set new(path) $path
        } else {
            # now we have to resolve
            while {![lempty $nparts]} {
                set piece [lshift nparts]
                if {$piece eq "."} {
                    continue
                } elseif {$piece eq ".."} {
                    if {[llength $parts] <= 1} {
                        error "invalid relative path $uri (base $base)"
                    }
                    # remove last element of base URI
                    set parts [lrange $parts 0 end-1]
                } else {
                    # append to base URI
                    lappend parts $piece
                }
            }
            set new(path) [join $parts /]
        }

        # clear query & fragment unless the new uri also has them
        unset new(query)
        unset new(fragment)
    }
    if {[part $up query]} {
        set new(query) $query
    }
    if {[part $up fragment]} {
        set new(fragment) $fragment
    }

    return [unparse [array get new]]
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
