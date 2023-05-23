# extra file system routines
package provide fsextra 0.1
package require logging
package require oscmd
package require platinfo

proc fnewer {f1 f2} {
    if {![file exists $f2]} {
        return 1
    }

    set mt1 [file mtime $f1]
    set mt2 [file mtime $f2]

    return $($mt1 > $mt2)
}

proc fcopy_macos {f1 f2} {
    # copy with cloning if possible
    oscmd run cp -c $f1 $f2
}

proc fcopy_unix {f1 f2} {
    # use unix copy, defaults to clone on many modern systems
    oscmd run cp $f1 $f2
}

proc fcopy_tcl {f1 f2} {
    # just use tcl copy
    file copy -force $f1 $f2
}

proc fcopy {f1 f2} {
    # find and cache best fcopy for platform
    if {![info exists ::fsextra::FCOPY]} {
        if {[plat::is mac]} {
            set ::fsextra::FCOPY fcopy_macos
        } elseif {[plat::is unix]} {
            set ::fsextra::FCOPY fcopy_unix
        } else {
            set ::fsextra::FCOPY fcopy_tcl
        }
    }

    if {[fnewer $f1 $f2]} {
        msg -trace "$::fsextra::FCOPY $f1 -> $f2"
        $::fsextra::FCOPY $f1 $f2
        return 1
    } else {
        msg -trace "$f2 up to date"
        return 0
    }
}

proc fsmirror args {
    set live 1
    set delete 0
    while {![lempty $args]} {
        set arg [lshift args]
        switch -- $arg {
            -dry-run {
                set live 0
            }
            -delete {
                set delete 1
            }
            -- {
                break
            }
            default {
                lunshift args $arg
                break
            }
        }
    }
    lassign $args srcroot dstroot
    if {![string length $srcroot]} {
        error "no source specified"
    }
    if {![string length $srcroot]} {
        error "no destination specified"
    }

    # we first scan p1 and copy files over, remembering copied files
    msg -debug "beginning copy pass"
    set copied [dict create]
    set ndirs 0
    set ncopies 0
    fswalk -relative path $srcroot {
        set src [file join $srcroot $path]
        set dst [file join $dstroot $path]
        if {[file isdirectory $src]} {
            msg -debug "mkdir $path"
            if {$live} {
                file mkdir $dst
            }
            incr ndirs
        } else {
            msg -debug "copy $path"
            if {$live} {
                fcopy $src $dst
            }
            incr ncopies
        }
        dict set copied $path 1
    }

    if {!$delete} {
        msg "mirrored $srcroot -> $dstroot ($ndirs dirs, $ncopies files)"
        return $ncopies
    }

    # now we delete
    msg -debug "beginning delete pass"
    set ndeletes 0
    fswalk -relative -dirs-last path $dstroot {
        if {![dict exists $copied $path]} {
            set dst [file join $dstroot $path]
            msg -debug "rm $path"
            if {$live} {
                file delete $dst
            }
            incr ndeletes
        }
    }

    msg "mirrored $srcroot -> $dstroot ($ndirs dirs, $ncopies files, $ndeletes removed)"
    return $ncopies
}

proc fswalk {args} {
    set dirs first
    set rel_paths 0
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
            -relative {
                set rel_paths 1
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
    set stack [lmap path $paths {list root $path}]
    msg -debug "scanning [llength $stack] paths"
    while {![lempty $stack]} {
        set next [lshift stack]
        lassign $next action path
        msg -trace "scan: $action $path"
        switch -- $action {
            invoke {
                if {$rel_paths} {
                    set cur_path [string range $path [string length $root] end]
                    set cur_path [regsub {^/*} $cur_path ""]
                    if {$cur_path eq ""} {
                        set cur_path .
                    }
                } else {
                    set cur_path $path
                }
                uplevel $body
            }
            root {
                set root $path
                lunshift stack [list visit $path]
            }
            visit {
                if {[file isdirectory $path]} {
                    set path [regsub {/*$} $path ""]
                    set kids [lsort [glob -nocomplain $path/*]]
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

# read_file --
#
#   read a file.
proc read_file {path} {
    set fp [open $path r]
    catch {
        read $fp
    } res opts
    close $fp
    return {*}$opts $res
}
