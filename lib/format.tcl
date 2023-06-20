package provide format 0.1
package require missing

namespace eval fmt {
    namespace export duration
    namespace ensemble create
}

proc fmt::_dur_stage {outVar durVar suffix seconds} {
    upvar $outVar out
    upvar $durVar dur
    if {$dur > $seconds} {
        set ud [expr {int($dur / $seconds)}]
        append out [format "%d%s" $ud $suffix]
        set dur [expr {$dur - ($ud * $seconds)}]
    }
}

proc fmt::duration {dur} {
    set res ""

    _dur_stage res dur d [expr {24 * 3600}]
    _dur_stage res dur h 3600
    _dur_stage res dur m 60

    if {$dur} {
        append res [format "%.2fs" $dur]
    }

    return $res
}

