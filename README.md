# ListCppWarningOptions #

A simple Perl script that prints GCC warning options you can apply to C++ code. A poor man's equivalent of Clang's `-Weverything` with a couple of extra tricks up its sleeve.

## Motivation ##

GCC online documentation scatters C++ related warning options across two pages and mixes them with options that have no meaning for C++. Furthermore, you have to [find](https://gcc.gnu.org/releases.html) the documentation suitable for your release.

`list_cpp_warning_options.pl` queries *your* local GCC, filters out options that can not be applied to C++, and prints them on the screen.

## Usage ##

```
USAGE:    ./list_cpp_warning_options.pl [options]
OPTIONS:
  -h, --help                Print this message.
  -p, --print-descriptions  Print option descriptions in the following format:
                            -Wuseless-cast        Warn about useless casts.
                            -Wunused-label        Warn when a label is unused.
                            ...
  -e, --enabled-only        Print only currently enabled warning options.
                            Useful to see what you have so far.
  -d, --disabled-only       Print only currently disabled warning options.
                            Useful to see what else can be enabled.
  GCC warning options       Assorted GCC warning options: -Wall, -Wextra,
                            -Wno-deprecated, etc.
                            Use with `--enabled-only` or `--disabled-only`.

  Options `--enabled-only` and `--disabled-only` cannot be used together.
```

## Caveats ##

* Ignores `-f` options
* Ignores `-W` options that take arguments
* Uses whatever `gcc` it finds in `$PATH`

