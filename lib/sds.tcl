package provide sds 1.0

namespace eval sds {
    namespace export parse_list
    
    # split a string into commands, including comments, as parsed by TCL
    # this procedure from https://wiki.tcl-lang.org/page/cmdSplit
    # licensed under the TCL license
    proc commands script {
        set commands {}
        set chunk {} 
        foreach line [split $script \n] {
            append chunk $line
            if {[info complete $chunk\n]} {
                # $chunk ends in a complete Tcl command, and none of the
                # newlines within it end a complete Tcl command.  If there
                # are multiple Tcl commands in $chunk, they must be
                # separated by semi-colons.
                set cmd {}
                foreach part [split $chunk \;] {
                    append cmd $part
                    if {[info complete $cmd\n]} {
                        set cmd [string trimleft $cmd[set cmd {}] "\f\n\r\t\v "]

                        if {[string match #* $cmd]} {
                            #the semi-colon was part of a comment.  Add it back
                            append cmd \;
                            continue
                        }
                        #drop empty commands
                        if {$cmd eq {}} {
                            continue
                        }
                        lappend commands $cmd
                        set cmd {}
                    } else {
                        # No complete command yet.
                        # Replace semicolon and continue
                        append cmd \;
                    }
                }
                # Handle comments, removing synthetic semicolon at the end
                if {$cmd ne {}} {
                    lappend commands [string replace $cmd[set cmd {}] end end]
                }
                set chunk {} 
            } else {
                # No end of command yet.  Put the newline back and continue
                append chunk \n
            }
        }
        if {![string match {} [string trimright $chunk]]} {
            return -code error "Can't parse script into a\
                    sequence of commands.\n\tIncomplete\
                    command:\n-----\n$chunk\n-----"
        }
        return $commands
    }

    # inspired by https://wiki.tcl-lang.org/page/Scripted+List
    proc parse_list {{n 1} script} {
        set commands [commands $script]
        msg -debug "have [llength $commands] parts"
        set words [list]
        foreach cmd $commands {
            msg -debug "processing $cmd"
            # skip comments
            if {[string match #* $cmd]} {
                continue
            }
            # pass tokens of cmd as separate elements to the 'list' command
            # evaluate this in the parent context (to interpret variables there)
            lappend words {*}[uplevel $n list $cmd]
        }
        return $words
    }
}