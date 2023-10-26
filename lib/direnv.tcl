package provide direnv 0.1
package require logging

proc {direnv apply} {} {
    set data [exec direnv export json 2>@stderr]
    if {[string trim $data] eq ""} {
        msg -debug "environment string is empty"
        return
    }
    msg -trace "environment: $data"
    set vars [json::decode $data]
    msg "applying directory environment"
    foreach {name value} $vars {
        msg -debug "setting env var $name"
        set ::env($name) $value
    }
}

ensemble direnv
