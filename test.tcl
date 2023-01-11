# Run the common suite tests.

package require tcltest 2.0
namespace import tcltest::*

set rootdir [file dirname [info script]]
set auto_path [linsert $auto_path 0 "$rootdir/lib"]

configure -testdir test

runAllTests
