# runprog.tcl -- run external programs
#
#   This package provides routines that support running external programs.
package provide runprog 1.0
package require logging
package require missing

proc run {args} {
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
            -retfail {
                set fail_action return
                lshift args
            }
            default {
                break
            }
        }
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
    if {$status} {
        # something failed
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
        return 0
    }
}
