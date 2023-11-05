# TCL task runner
package provide runner 0.1
package require logging
package require missing
package require kvlookup
package require ansifmt
package require formats

namespace eval runner {
    variable task_info
    variable cli_tasks [list]
    variable cli_mode dispatch
}
logging::ns_msg runner
namespace eval runner::tasks {}

proc runner::task_names {} {
    variable task_info
    return [lsort [array names task_info]]
}

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

proc runner::_order_visit {task listVar statVar {state required}} {
    variable task_info
    upvar $listVar sorted
    upvar $statVar status

    set append 1
    set tgt_state $state
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
                # we need to propgate required status to deps, but not add to list
                set append false
            } else {
                return
            }
        }
        required {
            # task already enqueued
            return
        }
    }

    set status($task) visiting
    foreach dep [dict get $task_info($task) deps] {
        _order_visit $dep sorted status $tgt_state
    }

    msg -debug "adding $task to work list"
    set status($task) $tgt_state
    if {$append} {
        lappend sorted $task
    }
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
        if {![exists task_info($task)]} {
            msg -error "unknown task $task"
            error "task $task does not exist"
        }
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
    set status [catch {
        ::runner::tasks::$name
    } rv rvopts]
    set finish [clock milliseconds]
    set elapsed [expr {($finish - $start) / 1000.0}]
    dict set task_info($name) time $elapsed
    if {$status} {
        msg -error task -fg white $name -fg red failed: -reset $rv
        return {*}$rvopts $rv
    } else {
        msg task -bold $name -reset "completed successfully in" -fg green [fmt duration $elapsed]
    }
}

proc runner::dispatch {tasks} {
    variable task_info
    set start [clock milliseconds]
    set worklist [sort_tasks $tasks]
    set status [catch {
        foreach task $worklist {
            run_task $task
        }
    } retval retopts]

    set finish [clock milliseconds]
    set elapsed [expr {($finish - $start) / 1000.0}]
    if {$status} {
        msg -error "task graph failed in" [fmt duration $elapsed]
        return {*}$retopts $retval
    } else {
        msg -success "finished in" -fg white [fmt duration $elapsed]
        foreach task $worklist {
            set time [dict get $task_info($task) time]
            msg -debug -bold $task -reset -fg white "took" -bold [fmt duration $elapsed]
        }
    }
}

proc runner::list_tasks {tasks} {
    variable task_info
    if {[lempty $tasks]} {
        set tasks [array names task_info]
        set tasks [lsort $tasks]
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

# parse command-line options for the runner, with optional extra options
proc runner::parse_cli {argv {extra ""}} {
    variable cli_spec
    variable cli_argv $argv
    set cli_spec {
        -v - --verbose {
            # increase logging verbosity
            logging::config -verbose
        }
        -q - --quiet {
            # suppress informational messages
            logging::config -quiet
        }
    }
    append cli_spec $extra
    append cli_spec {
        -l - --list {
            # list available tasks
            set ::runner::cli_mode list
        }
        --no-deps {
            # run just the task, without its dependencies
            set ::runner::cli_mode run_task
        }

        arglist {
            # [TASK]...
            if {![lempty $arg]} {
                lappend ::runner::cli_tasks [lshift arg]
            }
            set ::runner::cli_argv $arg
        }
    }
    # ugly hack to allow options intermixed with tasks
    # run in uplevel in case the client code sets variables
    uplevel {
        while {![lempty $::runner::cli_argv]} {
            getopt arg $::runner::cli_argv $::runner::cli_spec
        }
    }
}

# run the task list set up by parsing the CLI options
proc runner::run_cli {} {
    variable cli_mode
    variable cli_tasks
    switch -- $cli_mode {
        dispatch -
        single {
            if {[lempty $cli_tasks]} {
                msg "no task specified, running build"
                set cli_tasks build
            }
            runner::$cli_mode $cli_tasks
        }
        list {
            runner::list_tasks $cli_tasks
        }
        default {
            error "invalid mode $cli_mode"
        }
    }
}

alias task runner::add_task
