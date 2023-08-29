package provide mkyaml 0.1
package require missing
# UNFINISHED DO NOT USE

namespace eval mkyaml {
    variable nyamls 0
    variable yamls

    proc _attr {name args} {
        variable yamls
        set arg [lshift args]
        if {$arg eq "-set"} {
            set key [lshift args]
            set value [lshift args]
            dict set yamls $name $key $value
        } else {
            return [dict get $yamls $name $arg]
        }
    }

    proc _puts {name args} {
        set file [_attr $name file]
        puts $file {*}$args
    }

    # write YAML to $file
    proc open {file} {
        variable nyamls
        variable yamls
        incr nyamls
        set name "__yaml_$nyamls"
        set yaml [dict create file $file state none level 0 pos 0]
        dict set yamls $name yaml

        proc ::$name {cmd args} {
            ::mkyaml::$cmd $name {*}$args
        }
    }

    # close and tear down the YAML constructor
    proc close {name} {
        variable yamls
        set pos [_attr $name pos]
        if {$pos > 0} {
            _puts $name ""
        }
        rename ::$name ""
        dict remove yamls $name
    }

    # begin an object
    proc begin_object {name {key ""}} {
    }
}

