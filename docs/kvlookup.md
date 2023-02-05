# kvlookup

The `kvlookup` module implements a single procedure, `kvlookup`, that provides
flexible lookup for keys in key-value structures like arrays and dictionaries.

Load this with:

```tcl
package require kvlookup
```

> **kvlookup** ?-default *default*? (-array *var* | -var *var* | *dict*) *key*

The options are as follows:

- `-default` *default* — return the value *default* instead of an error if the key is not found.
- `-array` *var* — look up in the array named *var*.
- `-var` *var* — look up in the dictionary or array (auto-detected) named *var*.
- *dict* — look up in the provided dictionary value.
- *key* — the key to retrieve.

Future versions of this will support nested key retrieval.
