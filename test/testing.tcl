source [file dirname [info script]]/../tcltest.tcl

set auto_path [list [file dirname [info script]]/../lib {*}$auto_path]

# - dictsort -
#
#  Sorts a dictionary by its keys so that in its list representation the keys
#  are found in ascending alphabetical order, making it easier to directly
#  compare another dictionary.
#
# This procedure is from tcllib; see LICENSE.md for license and copyright.
# Copyright (c) 2006, Andreas Kupries <andreas_kupries@users.sourceforge.net>
#
# Arguments:
#	dict:	The dictionary to sort.
#
# Result:
#	The canonical representation of the dictionary.

proc dictsort {dict} {
    array set a $dict
    set out [list]
    foreach key [lsort [array names a]] {
	lappend out $key $a($key)
    }
    return $out
}