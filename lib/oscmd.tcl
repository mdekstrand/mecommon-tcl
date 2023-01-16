# oscmd -- run external programs
#
#   This package provides routines for working with external commands.
package provide oscmd 1.0
package require logging
package require missing

namespace eval oscmd {}

proc oscmd::locate {name} {
    msg -trace "asking which for $name"
    set failed [catch {
        exec which $name
    } rval ropts]

    # did we succeed?
    if {!$failed} {
        set rval [string trim $rval]
        msg -debug "found $name with which: $rval"
        return $rval
    }

    # did we successfully fail to locate the program?
    set ec [dict get $ropts -errorcode]
    set code [lindex $ec 0]
    if {$code eq "CHILDSTATUS"} {
        msg -trace "$rval not found, which failed with code [lindex $ec 2]"
        return -code error -errorcode {OSCMD NOTFOUND} "$name not found"
    }

    # ok, so we couldn't even run `which`. let's go hunting.
    set sep $::tcl_platform(pathSeparator)
    foreach varname {PATH Path} {
        if {[info exists ::env($varname)]} {
            set search_paths [split $::env($varname) $sep]
        }
    }
    if {![info exists search_paths]} {
        error "no PATH variable found"
    }
    set exts {""}
    if {[info exists ::env(PATHEXT)]} {
        # windows thing
        set exts [split $::env(PATHEXT) $sep]
    }
    foreach path $search_paths {
        foreach ext $exts {
            set fn [file join $path "$name$ext"]
            msg -trace "checking $fn"
            if {[file exists $fn]} {
                return $fn
            }
        }
    }

    # got to the end and it isn't there
    return -code error -errorcode {OSCMD NOTFOUND} "$name not found"
}

proc oscmd::exists {name} {
    set failed [catch {
        locate $name
    } rv opts]
    if {!$failed} {
        return 1
    } elseif {[dict get $opts -errorcode] eq {OSCMD NOTFOUND}} {
        return 0
    } else {
        return {*}$opts $rv
    }
}

proc oscmd::run {args} {
    set out @stdout
    set done 0
    set fail_action error
    while {!$done} {
        set arg [lpeek $args]
        switch -- $arg {
            -noout {
                set out /dev/null
                lshift args
            }
            -outfile {
                lshift args
                set out [lshift args]
            }
            -retfail {
                set fail_action return
                lshift args
            }
            -cwd {
                lshift args
                set cwd [lshift args]
            }
            default {
                break
            }
        }
    }

    if {[info exists cwd]} {
        set oldwd [pwd]
        msg -debug "entering directory $cwd"
        cd $cwd
    }

    set disp $args
    if {[llength $disp] > 10} {
        set disp [lrange $disp 0 9]
        lappend disp "..."
    }
    msg -debug "running command: $disp"
    set status [catch {
        exec {*}$args >$out 2>@stderr
    } retval retopts]
    if {[info exists cwd]} {
        msg -debug "restoring working directory"
        cd $oldwd
    }
    if {$status} {
        # something failed
        msg -debug "exec failed: $retval"
        if {[string equal $fail_action return]} {
            set details [dict get $retopts -errorcode]
            msg -debug "[lpeek $args]: failed with $details"
            set errcode [lpeek $details]
            if {[string equal $errcode CHILDSTATUS]} {
                set exit [lindex $details 2]
                msg -debug "terminated with code $exit"
                return $exit
            }
        }

        # no error to return
        return {*}$retopts $retval
    } else {
        msg -debug "exec ok"
        return 0
    }
}

proc oscmd {name args} {
    uplevel 1 "oscmd::$name" {*}$args
}
