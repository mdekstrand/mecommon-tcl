# operations on sets (represented as lists)
package provide setops 0.1
package require missing

namespace eval setops {
    proc union {args} {
        foreach set $args {
            foreach elt $set {
                incr found($elt)
            }
        }
        if {[array exists found]} {
            return [array names found]
        } else {
            return [list]
        }
    }
}

proc setop {cmd args} {
    set op "::setops::$cmd"
    if {[exists -command $op]} {
        $op {*}$args
    } else {
        error "unknown set command $op"
    }
}
