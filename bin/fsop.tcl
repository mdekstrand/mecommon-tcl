#!/usr/bin/env jimsh
#
# Perform file operations.

set root [file dirname [file dirname [file normalize [info script]]]]
set auto_path [list $root/lib {*}$auto_path]

package require logging
package require getopt
package require missing
package require fsextra

getopt arg $argv {
    -v - --verbose {
        # increase logging verbosity
        logging::configure -verbose
    }

    arglist {
        set command [lshift arg]
        set args $arg
    }
}

switch $command {
    copy {
        if {[llength $args] != 2} {
            msg -error "COPY requires exactly 2 arguments"
            exit 2
        }
        fcopy {*}$args
    }
    default {
        msg -error "unknown command $command"
        exit 2
    }
}
