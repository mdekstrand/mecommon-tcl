# extra file system routines
package provide fsextra 0.1
package require logging

proc fnewer {f1 f2} {
    if {![file exists $f2]} {
        return 1
    }

    set mt1 [file mtime $f1]
    set mt2 [file mtime $f2]

    return $($mt1 > $mt2)
}

proc fcopy {f1 f2} {
    if {[fnewer $f1 $f2]} {
        msg "copying $f1 -> $f2"
        file copy -force $f1 $f2
    } else {
        msg -debug "$f2 up to date"
    }
}

proc fswalk {args} {
    set dirs first
    while {![lempty $args]} {
        set arg [lshift args]
        switch -- $arg {
            -dirs {
                set dirs [lshift args]
            }
            -dirs-last {
                set dirs last
            }
            -no-dirs {
                set dirs skip
            }
            -- {
                break
            }
            -* {
                error "unrecognized option $arg"
            }
            default {
                # we are done
                break
            }
        }
    }
    set var $arg
    set paths [lshift args]
    set body [lshift args]

    # alias the variable the body will need
    upvar $var cur_path
    
    # now work the process - the stack maintains the current work list
    set stack [lmap path $paths {list visit $path}]
    msg -debug "scanning [llength $stack] paths"
    while {![lempty $stack]} {
        set next [lshift stack]
        lassign $next action path
        msg -trace "scan: $action $path"
        switch -- $action {
            invoke {
                set cur_path $path
                uplevel $body
            }
            visit {
                if {[file isdirectory $path]} {
                    set path [regsub {/*$} $path ""]
                    set kids [lsort [glob $path/*]]
                    # since we use a (weird) stack, last needs to be pushed first
                    if {$dirs eq "last"} {
                        lunshift stack [list invoke "$path/"]
                    }
                    lunshift stack {*}[lmap kp $kids {list visit $kp}]
                    if {$dirs eq "first"} {
                        lunshift stack [list invoke "$path/"]
                    }
                } else {
                    lunshift stack [list invoke $path]
                }
            }
        }
    }
}

proc copytree {src dst} {
    
}
