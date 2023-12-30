# Support for "tagged lines", like BSD hash tool output. These are of the form:
# TAG(SUBJECT)= VALUE
# Once parsed, taglines are represented as a list: {SUBJECT TAG VALUE}
package provide tagline 0.1
package require missing

namespace eval tagline {}
proc tagline::parse {args} {
    set norm_sha 0
    if {[lpeek $args] == "-norm-hash"} {
        set norm_sha 1
        lshift args
    }
    set line [lshift args]
    if {![lempty $args]} {
        error "too many arguments"
    }
    set line [string trim $line]
    if {[regexp {^([A-Z0-9-]+)\s*\(([^)]+)\)\s*=\s*(.*)} $line -> tag subject value]} {
        if {$norm_sha} {
            set tag [regsub {^SHA2-(\d+)} $tag {SHA\1}]
        }
        return [list $subject $tag $value]
    } else {
        error "invalid tagline: $line"
    }
}

proc tagline::unparse {args} {
    if {[llength $args] == 1} {
        set obj [lshift args]
        lassign $obj subject tag value
    } elseif {[llength $args] == 3} {
        lassign $args subject tag value
    } else {
        error "incorrect number of arguments"
    }
    return "$tag ($subject) = $value"
}

proc tagline::subject {obj} {
    lassign $obj o(subject) o(tag) o(value)
    return $o(subject)
}

proc tagline::tag {obj} {
    lassign $obj o(subject) o(tag) o(value)
    return $o(tag)
}

proc tagline::value {obj} {
    lassign $obj o(subject) o(tag) o(value)
    return $o(value)
}

proc tagline::readfile {path} {
    set h [open $path r]
    set lines [list]
    while {[gets $h line] >= 0} {
        set line [string trim $line]
        if {$line ne ""} {
            lappend lines [tagline parse $line]
        }
    }
    close $h
    return $lines
}

proc tagline::dict {key taglines} {
    set dict [::dict create]
    foreach line $taglines {
        lassign $line subject tag value
        if {$tag eq $key} {
            ::dict set dict $subject $value
        }
    }
    return $dict
}

namespace eval tagline {
    namespace export parse unparse readfile
    namespace export subject tag value dict
    namespace ensemble create
}
