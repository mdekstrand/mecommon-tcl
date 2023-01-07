# testopts.tcl: test the getopt library

package require logging
package require getopt

logging::configure -verbose
msg "parsing arguments: $argv"

getopt arg $argv {
    -h? - --help {
        # print usage help and exit
        msg "received --help"
        help
    }
    -x: - --extended:ARG {
        # extended property ARG
        msg "ext $arg"
    }
    missing {
        msg -err "no value found for $arg"
    }
    unknown {
        msg -err "unknown argument $arg"
    }
    arglist {
        msg "finished, [llength $arg] arguments remaining"
        msg "args: $arg"
    }
}
