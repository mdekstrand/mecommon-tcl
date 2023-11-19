# missing.tcl --
#
#   Polyfills for missing functionality TCL or JimTcl should arguably have, and very small
#   add-on procedures.
package provide missing 1.1

# lshift --
#
#   Remove and return an item from the front of a list.  This is based on
#   https://wiki.tcl-lang.org/page/lshift.
proc lshift {listVar} {
    upvar 1 $listVar list
    if {![info exists list]} {
        error "lshift: variable $listVar does not exist"
    } elseif {[llength $list] == 0} {
        error "lshift: list $listVar is empty"
    }
    set x [lindex $list 0]
    set list [lreplace $list [set list 0] 0]
    return $x
}

# lunshift --
#   Push a value onto the front of a list.
proc lunshift {listVar args} {
    upvar 1 $listVar list
    if {![info exists list]} {
        error "lunshift: variable $listVar does not exist"
    }
    set list [linsert $list [set list 0] {*}$args]
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

# luniq --
#
#   Get the unique elements of a list.
proc luniq {list} {
    set result [list]
    foreach e $list {
        if {![info exists found($e)]} {
            lappend result $e
            set found($e) 1
        }
    }
    return $result
}

# lglob --
#
#   filter a list based on a glob
proc lglob args {
    set invert 0
    while {![lempty $args]} {
        set arg [lpeek $args]
        switch -glob -- $arg {
            -invert {
                set invert 1
                lshift args
            }
            -- {
                break
            }
            -* {
                error "unexpected argument $arg"
            }
            default {
                break
            }
        }
    }
    lassign $args glob list
    set result [list]
    foreach x $list {
        set want [string match $glob $x]
        if {$invert} {
            set want [expr {!$want}]
        }
        if {$want} {
            lappend result $x
        }
    }

    return $result
}

# exists --
#
#   A Jim-like 'exists' procedure for core Tcl.  Only tests variables for now.
if {"exists" ni [info commands]} {
    proc exists {name args} {
        set mode var
        set nsfilt ""
        if {[string match $name* -var]} {
            set name [lshift args]
        } elseif {[string match $name* -proc]} {
            set mode proc
            set name [lshift args]
        } elseif {[string match $name* -command]} {
            set mode cmd
            set name [lshift args]
        } elseif {[string match $name* -alias]} {
            set mode alias
            set name [lshift args]
        }

        switch $mode {
            var {
                return [uplevel 1 info exists $name]
            }
            proc {
                set list [uplevel 1 info procs $name]
                return [expr {[llength $list] > 0}]
            }
            cmd {
                set list [uplevel 1 info commands $name]
                return [expr {[llength $list] > 0}]
            }
            alias {
                error "exists -alias not yet supported"
            }
            default {
                error "unknown mode"
            }
        }
    }
}

# Jim-compatible `env` procedure.
if {"env" ni [info commands]} {
    proc env {name args} {
        if {[info exists ::env($name)]} {
            return $::env($name)
        } elseif {[llength $args] > 0} {
            lassign $args dft
            return $dft
        } else {
            error "unknown environment variable $env"
        }
    }
}

if {![exists -command alias]} {
    proc alias {name args} {
        interp alias {} $name {} {*}$args
    }
}
