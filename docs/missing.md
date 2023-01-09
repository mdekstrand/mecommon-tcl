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

## kvlookup

The `kvlookup` routine provides flexible lookup for keys in key-value structures
like arrays and dictionaries.

> **kvlookup** ?-default *default*? (-array *var* | -var *var* | *dict*) *key*

The options are as follows:

- `-default` *default* — return the value *default* instead of an error if the key is not found.
- `-array` *var* — look up in the array named *var*.
- `-var` *var* — look up in the dictionary or array (auto-detected) at `$var`.
- *dict* — look up in the provided dictionary value.
- *key* — the key to retrieve.
