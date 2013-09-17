Simple utility to analyse symbol dependency graph in object files
=================================================================

Synopsis
--------

This is a simple utility that uses `objdump` to disassemble code sections in an
object file or executable, and builds a dependency graph between symbols.

Examples:
````
symdep -h                 # display information about command-line options
symdep program.o -r main  # include only symbols reachable from "main"
symdep program.o -u main  # include only symbols NOT reachable from "main"
symdep program.o -f dot   # output DOT format
````

Description
-----------

A symbol X is considered to depend on another symbol Y if somewhere between X
and the subsequent symbol there's a reference to Y. Offsets are ignored for the
purposes of this program, so static functions or variables whose symbols have
been stripped may throw off the dependency graph somewhat.

The primary purpose of this utility is to identify which symbols are
unreachable from the main program, and thus are candidates for exclusion during
compilation and linking.

Note that currently, this program only works on Posix systems or systems where
`objdump` exists and produces output understood by it.

The program can output the resulting graph in GraphViz's DOT format, which can
then be visualized with the help of `dot` or one of the other graph layout
programs from the GraphViz package. Be forewarned, however, that attempting to
render the entire dependency graph of a non-trivial program may take a LOT of
system resources, and the result will probably be rather unhelpful (it will
look like somebody's hair on a bad hair day).

Building
--------

Requirements: a D compiler (2.063.2 or later).

To build:
````
dmd symdep.d
````
