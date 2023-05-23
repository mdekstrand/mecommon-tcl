#!/usr/bin/env jimsh
#
# Test program for fsextra's walk

set root "[file dirname [info script]]/.."
set auto_path [list $root/lib {*}$auto_path]

package require logging
package require getopt
package require fsextra

set walk_args [list]

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

    arglist {
        set paths $arg
    }
}

fswalk {*}$walk_args path $paths {
    msg "visted $path"
}
