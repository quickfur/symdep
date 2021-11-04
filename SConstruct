#!/usr/bin/scons

env = Environment(
    DC = '/usr/src/d/ldc/latest/bin/ldc2',
    DFLAGS = [
        '-O2'
    ]
)

env.Command('symdep', Split("""
        symdep.d
    """),
    "$DC $DFLAGS $SOURCES -of=$TARGET"
)
