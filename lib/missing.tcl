# missing.tcl --
#
#   Polyfills for missing functionality TCL or JimTcl should arguably have.
package provide missing 1.0

# lshift --
#
#   Remove and return an item from the front of a list.  This is inspired by
#   https://wiki.tcl-lang.org/page/lshift, but simpler at the expense of slight efficiency.
proc lshift {listVar} {
    upvar 1 $listVar list
    if {![info exists list]} {
        error "lshift: variable $listVar does not exist"
    } elseif {[llength $list] == 0} {
        error "lshift: list $listVar is empty"
    }
    set x [lindex $list 0]
    set list [lreplace $list 0 0]
    return $x
}

# lempty --
#
#   Query whether a list is empty.
proc lempty {list} {
    return [expr {[llength $list] == 0}]
}

# exists --
#
#   A Jim-like 'exists' procedure for stock Tcl.  Only tests variables.

if {"exists" ni [info commands]} {
    proc exists {var} {
        return [info exists $var]
    }
}
