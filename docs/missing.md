# Missing Library

The `missing` package provides several routines that are “missing” from the
basic TCL environment.  These are little bits that round out existing
functionality, or in some cases polyfill functions that either Jim or Tcl
lack from the other's features.

Use this package with:

```tcl
package require missing
```

## List Routines

These routines work with lists.

### lshift

[lshift]: https://wiki.tcl-lang.org/page/lshift

`lshift listVar` removes and returns the *first* element of the list in
`listVar`.  Its implementation is derived from the [tcl wiki][lshift].

It does not fail on an empty list.

### lempty

`lempty list` returns true if `list` is empty.

### lpeek

`lpeek list` returns the first element of the list *without* removing it.
