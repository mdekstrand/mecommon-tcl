package provide direnv 0.1
package require logging

proc {direnv apply} {} {
    set data [exec direnv export json 2>@stderr]
    set vars [json::decode $data]
    msg "applying directory environment"
    foreach {name value} $vars {
        msg -debug "setting env var $name"
        set ::env($name) $value
    }
}

ensemble direnv
