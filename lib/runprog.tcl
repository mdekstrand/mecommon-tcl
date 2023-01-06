package provide runprog 1.0
package require logging

proc run {args} {
    set disp $args
    if {[llength $disp] > 10} {
        set disp [lrange $disp 0 9]
        lappend disp "..."
    }
    msg -debug "running command: $disp"
    exec {*}$args >@stdout 2>@stderr
}
