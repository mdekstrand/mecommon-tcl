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

### luniq

`luniq list` returns the unique elements of `list`.  Order is preserved — each element is
returned the *first* time it appears in `list`, and subsequent occurrences are skipped.

## Info Routines

### exists

The `exists` procedure is a mostly-compatible polyfill to provide Jim's `exists`
command on Tcl.

## I/O routines

### read_file

The `read_file` procedure reads the contents of a file.
