# extra file system routines
package provide fsextra 0.1
package require logging

proc fnewer {f1 f2} {
    if {![file exists $f2]} {
        return 1
    }

    set mt1 [file mtime $f1]
    set mt2 [file mtime $f2]

    return $($mt1 > $mt2)
}

proc fcopy {f1 f2} {
    if {[fnewer $f1 $f2]} {
        msg "copying $f1 -> $f2"
        file copy -force $f1 $f2
    } else {
        msg -debug "$f2 up to date"
    }
}
