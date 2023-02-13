#!/usr/bin/env jimsh

set root [file dirname [info script]]
set auto_path [list "$root/lib" {*}$auto_path]

package require logging
package require missing
package require oscmd
package require getopt

getopt arg $argv {
    -v - --verbose {
        # increase logging verbosity
        logging::configure -verbose
    }

    --push {
        set mode push
    }
    --pull {
        set mode pull
    }
}

if {![exists mode]} {
    msg -error "no mode specified"
    exit 2
}

set common [file normalize $root]
set parent [file dirname $common]

if {![file exists [file join $parent .git]]} {
    msg -error "$parent is not a git repo"
    exit 3
}
cd $parent
set prefix [file tail $common]

switch $mode {
    push {
        msg "pushing local changes to common git"
        oscmd run git fetch common
        oscmd run git subtree push --prefix=$prefix common main
    }
    pull {
        msg "pulling new changes from common git"
        oscmd run git fetch common
        oscmd run git subtree pull --prefix=$prefix common main --squash
    }
}
