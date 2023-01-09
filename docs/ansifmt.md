# ansifmt

`ansifmt` is a small package that provides access to basic ANSI terminal
formatting codes.  It primarily exists to allow [`logging`](logging.md) to color
its output.

Its interface is provided through one routine, `ansi::fmt`:

> **ansi::fmt** *flags*

It returns the corresponding ANSI escape sequence, suitable for emitting to
the terminal through something like `puts`.

Supported flags:

- `-reset`
- `-bold`
- `-dim`
- `-ul`
- `-fg` *color*
- `-bg` *color*

Only the 8 base colors are supported at this time.

- black
- red
- green
- yellow
- blue
- magenta
- cyan
- white
