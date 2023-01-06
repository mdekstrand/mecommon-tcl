# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded ansifmt 0.1 [list source [file join $dir lib/ansifmt.tcl]]
package ifneeded logging 0.1 [list source [file join $dir lib/logging.tcl]]
package ifneeded missing 1.0 [list source [file join $dir lib/missing.tcl]]
package ifneeded platinfo 0.1 [list source [file join $dir lib/platinfo.tcl]]
package ifneeded runprog 1.0 [list source [file join $dir lib/runprog.tcl]]
