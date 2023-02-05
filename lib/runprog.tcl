# runprog.tcl -- run external programs
#
#   This package provides routines that support running external programs.
package provide runprog 0.1
package require logging
package require missing
package require oscmd

proc run {args} {
    msg -warn "deprecated run proc, use oscmd"
    return [oscmd run {*}$args]
}
