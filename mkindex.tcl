#!/usr/bin/env tclsh

if {[llength $argv]} {
    set dir [lindex $argv 0]
    puts "indexing $dir"
    pkg_mkIndex -verbose $dir {*}[lrange $argv 1 end]
} else {
    set dir [file dirname [info script]]
    puts "indexing common lib at $dir"
    cd $dir
    pkg_mkIndex -verbose lib *.tcl
}
