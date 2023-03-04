# Support for "tagged lines", like BSD hash tool output. These are of the form:
# TAG(SUBJECT)= VALUE
# Once parsed, taglines are represented as a list: {SUBJECT TAG VALUE}
package provide tagline 0.1
package require missing

proc tagline {cmd args} {
    switch -- $cmd {
        parse {
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
        unparse {
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
        subject -
        tag -
        value {
            set obj [lshift args]
            if {![lempty $args]} {
                error "too many arguments"
            }
            lassign $obj o(subject) o(tag) o(value)
            return $o($cmd)
        }
    }
}
