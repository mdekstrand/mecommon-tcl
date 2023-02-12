# TCL task runner
package provide runner 0.1
package require logging

namespace eval runner {
    variable task_deps
    variable task_status
}
logging::ns_msg runner

proc runner::add_task {name deps body} {
    variable task_deps
    variable task_status

    msg -debug "defining task $name"
    set task_deps($name) $deps
    set task_status($name) ready
    
    proc "::runner::tasks::$name" {} $body
}

proc runner::run_task {name} {
    variable task_deps
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
    foreach dep $task_deps($name) {
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
    foreach task $tasks {
        run_task $task
    }
}

alias task runner::add_task
