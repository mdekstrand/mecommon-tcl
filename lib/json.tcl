package provide json 0.1

if {[info exists ::jim::exe]} {
    set _json_mode jim
} else {
    set _json_mode alt
    package require jsonparse
}

proc parse_json {text} {
    global _json_mode
    switch $_json_mode {
        jim {
            return [json::decode $text]
        }
        alt {
            return [json::values [json::decode $text]]
        }
    }
}
