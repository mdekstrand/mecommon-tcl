#!/usr/bin/env jimsh
#
# Test program for fsextra's walk

set root [file dirname [file dirname [file normalize [info script]]]]
set auto_path [list $root/lib {*}$auto_path]

package require logging
package require getopt
package require fsextra

set walk_args [list]
set exclude [list]

getopt arg $argv {
    -v - --verbose {
        # increase logging verbosity
        logging::configure -verbose
    }

    --dirs-last {
        # print directories after their contents
        lappend walk_args -dirs-last
    }
    --no-dirs {
        # print directories after their contents
        lappend walk_args -no-dirs
    }
    --relative {
        # print paths relative to root
        lappend walk_args -relative
    }

    --exclude:PAT {
        # exclude paths matching PAT
        lappend exclude $arg
    }

    arglist {
        set paths $arg
    }
}

if {[llength $exclude]} {
    lappend walk_args -filter {
        set include 1
        foreach pat $::exclude {
            if {[string match $pat $path]} {
                set include 0
            }
        }
        set include
    }
}

fswalk {*}$walk_args path $paths {
    msg "visted $path"
}
