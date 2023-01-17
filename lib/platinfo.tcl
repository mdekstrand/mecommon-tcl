# platform.tcl --
#
#   Provide information about the system platform.
package provide platinfo 0.1
package require logging

namespace eval ::plat {
    variable cache
    array set cache {}

    # ::plat::tag --
    #
    #   Generate a short tag identifying this platform.
    proc tag {} {
        return "[os]-[arch]"
    }

    proc os {} {
        global tcl_platform
        if {$tcl_platform(platform) eq "windows"} {
            set plat windows
        } elseif {[regexp "^M(INGW|SYS2)" $tcl_platform(os)]} {
            set plat windows
        } else {
            set plat [string tolower $tcl_platform(os)]
        }

        return $plat
    }

    proc arch {} {
        global tcl_platform
        variable cache
        if {![info exists cache(arch)]} {
            if {[info exists tcl_platform(machine)]} {
                msg -debug "retrieving arch from \$tcl_platform(machine)"
                set cache(arch) $tcl_platform(machine)
            } else {
                # no machine in tcl_platform, we're probably on jim
                # let's try to get it from the 'arch' command
                try {
                    msg -debug "trying external arch command"
                    exec "arch"
                } on ok {output} {
                    set cache(arch) [string trim $output]
                } on error {msg opts} {
                    msg -warn "cannot determine architecture"
                    set cache(arch) unknown
                }
            }
        }

        return $cache(arch)
    }

    proc flavor {} {
        global tcl_platform
        if {$tcl_platform(platform) eq "windows"} {
            return windows
        } elseif {[regexp "^M(INGW|SYS2)" $tcl_platform(os)]} {
            return msys2
        } else {
            return [string tolower $tcl_platform(platform)]
        }
    }

    proc is {args} {
        set result 1
        foreach arg $args {
            switch -glob -- $arg {
                windows {
                    set result [expr {$result && [os] eq "windows"}]
                }
                unix {
                    # msys2 is both windows and unix
                    set result [expr $result && [flavor] in {unix msys2}]
                }
                -* {
                    set query [string range $arg 1 end]
                    set sr [is $query]
                    set result [expr $result && !$sr]
                }
                default {
                    error "unknown query $flag"
                }
            }
        }

        return $result
    }

    namespace export tag os arch is
}
