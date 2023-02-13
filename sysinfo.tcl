set root [file dirname [string map {\\ /} [info script]]]
set auto_path [list "$root/lib" {*}$auto_path]

package require logging
package require getopt
package require ansifmt
package require platinfo

proc display {label value} {
    ansi::with_out stdout {
        puts "$label: [ansi::wrap -bold $value]"
    }
}

getopt arg $argv {
    -v - --verbose {
        # increase logging verbosity
        logging::configure -verbose
    }
    -q - --quiet {
        # suppress informational messages
        logging::configure -quiet
    }
}

msg "reading TCL platform data"
foreach key [lsort [array names tcl_platform]] {
    display $key $tcl_platform($key)
}

msg "reading platform detection results"
display tag [plat::tag]
display arch [plat::arch]
display os [plat::os]
display flavor [plat::flavor]
display distro [plat::distro]
