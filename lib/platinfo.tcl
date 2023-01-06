# platform.tcl --
# 
#   Provide information about the system platform.
package provide platinfo 0.1

namespace eval ::plat {
    # ::plat::tag --
    #
    #   Generate a short tag identifying this platform.
    proc tag {} {
        global tcl_platform
        set os [string tolower $tcl_platform(os)]
        set arch $tcl_platform(machine)
        return "$os-$arch"
    }
}