# TCL task runner
package provide runner 0.1
package require logging
package require kvlookup
package require ansifmt

namespace eval runner {
    variable task_info
}
logging::ns_msg runner

proc runner::add_task {name deps body} {
    variable task_info

    msg -debug "defining task $name"
    set info [dict create deps $deps]
    if {[regexp -line {^#\s*(.*)} [string trim $body] -> descr]} {
        msg -debug "$name: $descr"
        dict set info description $descr
    }
    set task_info($name) $info
    
    proc "::runner::tasks::$name" {} $body
}

proc runner::_order_visit {task listVar statVar} {
    variable task_info
    upvar $listVar sorted
    upvar $statVar status

    set tgt_state required
    if {[string range $task end end] == "?"} {
        set tgt_state optional
        set task [string range $task 0 end-1]
    }
    msg -trace "visiting $task"

    switch $status($task) {
        visiting {
            msg -error "visiting $task twice: circular dependency"
            error "circular dependencies in task graph"    
        }
        optional {
            # task is enqueued, but see if we are supposed to upgrade it
            if {$tgt_state eq "required"} {
                set status($task) required
            }
            return
        }
        required {
            # task already enqueued
            return
        }
    }
    
    set status($task) visiting
    foreach dep [dict get $task_info($task) deps] {
        _order_visit $dep sorted status
    }

    msg -debug "adding $task to work list"
    set status($task) $tgt_state
    lappend sorted $task
}

proc runner::sort_tasks {roots} {
    # produce a sorted worklist to run roots
    variable task_info
    foreach name [array names task_info] {
        set dfs_status($name) available
    }

    # sort the tasks
    set task_order [list]
    foreach task $roots {
        _order_visit $task task_order dfs_status
    }

    # remove unused tasks
    set filtered [list]
    foreach task $task_order {
        switch $dfs_status($task) {
            required {
                lappend filtered $task
            }
            optional {
                msg -debug "task $task in order but not required, removing"
            }
            default {
                error "internal error: bad task status $dfs_status($task)"
            }
        }
    }

    msg -info "built work list with [llength $filtered] tasks"
    return $filtered
}

proc runner::run_task {name} {
    variable task_info

    set start [clock milliseconds]
    msg "beginning task $name"
    ::runner::tasks::$name
    set finish [clock milliseconds]
    set elapsed [expr {($finish - $start) / 1000.0}]
    msg task -bold $name -reset "completed successfully in" -fg green [format "%.2fs" $elapsed]
}

proc runner::dispatch {tasks} {
    set start [clock milliseconds]
    set worklist [sort_tasks $tasks]
    foreach task $worklist {
        run_task $task
    }
    set finish [clock milliseconds]
    set elapsed [expr {($finish - $start) / 1000.0}]
    msg -success "finished in" -fg white [format "%.2fs" $elapsed]
}

proc runner::list_tasks {tasks} {
    variable task_info
    if {[lempty $tasks]} {
        set tasks [array names task_info]
        msg "[llength $tasks] tasks defined"
    } else {
        msg "finding work order to build $tasks"
        set tasks [sort_tasks $tasks]
    }
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
