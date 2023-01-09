# missing.tcl --
#
#   Polyfills for missing functionality TCL or JimTcl should arguably have, and very small
#   add-on procedures.
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

# lunshift --
#   Push a value onto the front of a list.
proc lunshift {listVar val} {
    upvar 1 $listVar list
    if {![info exists list]} {
        error "lunshift: variable $listVar does not exist"
    }
    set list [linsert $list 0 $val]
}

# lempty --
#
#   Query whether a list is empty.
proc lempty {list} {
    return [expr {[llength $list] == 0}]
}

# lpeek --
#
#   Peek the front element of a list.
proc lpeek {list} {
    return [lindex $list 0]
}

# kvlookup -- look up keys in a key-value structure
proc kvlookup {args} {
    set mode auto
    while {![lempty $args]} {
        set arg [lshift args]
        switch -glob -- $arg {
            -array {
                set mode array
                set var [lshift args]
            }
            -var {
                set var [lshift args]
            }
            -default {
                set default [lshift args]
            }
            -* {
                error "kvlookup: unsupported flag $arg"
            }
            default {
                if {[info exists var]} {
                    # we have  var, so this is a key
                    lunshift args $arg
                } else {
                    # otherwise the first element is a dictionary value
                    set mode dict
                    set dict $arg
                }
                # either way, we're done.
                break
            }
        }
    }
    if {[lempty $args]} {
        error "no key specified"
    } elseif {[llength $args] > 1} {
        error "kvlookup only supports 1 key"
    }
    set key [lshift args]

    # now we have to carefully walk through our options.
    # first find out if arrays - jim can be compiled without them
    set have_array [expr {"array" in [info commands]}]

    # now start working through things. do we have a variable?
    if {[info exists var]} {
        # yes - alias it for further use
        upvar 1 $var kvv
        # and detect its mode if necessary
        if {$mode eq "auto"} {
            if {$have_array && [array exists kvv]} {
                set mode array
            } else {
                set mode dict
            }
        }

        # now, we can use it. dispatch on mode.
        switch -- $mode {
            array {
                # directly look up the array key
                if {[info exists kvv($key)]} {
                    return $kvv($key)
                } elseif {[info exists default]} {
                    return $default
                } else {
                    error -code {KVLOOKUP ARRAY UNFOUND} "array $var has no key $key"
                }
            }
            dict {
                # grab the dict and fall through
                set dict $kvv
            }
        }
    }

    # if we have reached this point, we are in dict mode with a dictionary in $dict
    if {[dict exists $dict $key]} {
        return [dict get $dict $key]
    } elseif {[info exists default]} {
        return $default
    } elseif {[info exists var]} {
        error -code {KVLOOKUP DICT UNFOUND} "dictionary in $var has no key $key"
    } else {
        error -code {KVLOOKUP DICT UNFOUND} "dictionary value has no key $key"
    }
}

# exists --
#
#   A Jim-like 'exists' procedure for core Tcl.  Only tests variables for now.
if {"exists" ni [info commands]} {
    proc exists {var} {
        return [info exists $var]
    }
}
