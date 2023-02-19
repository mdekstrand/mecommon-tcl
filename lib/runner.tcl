# TCL task runner
package provide runner 0.1
package require logging
package require kvlookup
package require ansifmt

namespace eval runner {
    variable task_info
    variable task_status
}
logging::ns_msg runner

proc runner::add_task {name deps body} {
    variable task_info
    variable task_status

    msg -debug "defining task $name"
    set info [dict create deps $deps]
    if {[regexp -line {^#\s*(.*)} [string trim $body] -> descr]} {
        msg -debug "$name: $descr"
        dict set info description $descr
    }
    set task_info($name) $info
    set task_status($name) ready
    
    proc "::runner::tasks::$name" {} $body
}

proc runner::run_task {name} {
    variable task_info
    variable task_status

    msg -trace "checking task $name"
    switch -- $task_status($name) {
        pending {
            msg -warn "$name already pending, circular dependency?"
            return
        }
        finished {
            msg -trace "task $name already finished"
            return
        }
    }

    set task_status($name) pending
    foreach dep [kvlookup -default {} -array task_info $name deps] {
        run_task $dep
    }

    set task_status($name) running
    set start [clock milliseconds]
    msg "beginning task $name"
    ::runner::tasks::$name
    set finish [clock milliseconds]
    set elapsed [expr {($finish - $start) / 1000.0}]
    msg task -bold $name -reset "completed successfully in" -fg green [format "%.2fs" $elapsed]
    set task_status($name) finished
}

proc runner::dispatch {tasks} {
    set start [clock milliseconds]
    foreach task $tasks {
        run_task $task
    }
    set finish [clock milliseconds]
    set elapsed [expr {($finish - $start) / 1000.0}]
    msg -success "finished in" -fg white [format "%.2fs" $elapsed]
}

proc runner::list_tasks {} {
    variable task_info
    set tasks [array names task_info]
    msg "[llength $tasks] tasks defined"
    ansi::with_out stdout {
        foreach task $tasks {
            set deps [kvlookup -default "" -array task_info $task deps]
            set desc [kvlookup -default "" -array task_info $task description]
            if {$desc eq ""} {
                puts "[ansi::fmt -bold]$task[ansi::fmt -reset]"
            } else {
                puts "[ansi::fmt -bold]$task[ansi::fmt -reset]: $desc"
            }
        }
    }
}

alias task runner::add_task
