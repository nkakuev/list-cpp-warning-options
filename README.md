# ListCppWarningOptions #

A simple Perl script that prints GCC warning options you can apply to C++ code. A poor man's equivalent of Clang's
`-Weverything`.

## Motivation ##

GCC online documentation scatters C++ related warning options across two pages and mixes them with options that have no meaning
for C++. Furthermore, online documentation exists only for latest full GCC releases.

`list_cpp_warning_options.pl` queries *your* version of GCC, filters out options that can not be applied to C++, and prints them
on the screen.

## Usage ##

```
./list_cpp_warning_options.pl [--print-descriptions]
```

Specifying `--print-descriptions` will also print options' descriptions. Use it to familiarize yourself with the warning arsenal
of GCC.

## Caveats ##

* Ignores `-f` options
* Ignores `-W` options that take arguments
* Uses whatever `gcc` it finds in `$PATH`

