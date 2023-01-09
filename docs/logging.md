# Logging

The `logging` package provides a basic logging with zero dependencies (other
than the included `ansifmt` package) that works on both Jim and Tcl.

To use this library, simply require it:

```tcl
package require logging
```

## msg

The primary feature of this library is the `msg` procedure:

> **msg** ?-level? *message*

The following levels are supported:

- `-debug` — debug-level logging, disabled by default.
- `-info` — informational messages, enabled by default.
- `-warn` — warning messages, enabled by default.
- `-error` — error messages, enabled by default. `-err` is accepted as an alias.
- `-success` — the same level as `-info`, but highlighted to more clearly indicate a success message.

## configure

The `logging::configure` procedure reconfigures logging behavior.
It takes flags to control its output:

- `-quiet` — silence `-info` messages, only printing warnings and errors.
- `-verbose` — enable `-debug` messages.
- `-level level` — set the logging level to 'level'
