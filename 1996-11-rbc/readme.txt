Hello RBC user.

This is just a fast how-to, I don't have enough time to make a real manual.

The version 1.4 can be used in two forms: with and without optimzation.
To run RBC, just use the batch files:

RUN.BAT         - generate 8088 (PC) binaries without optimzations.
RUNZ80.BAT      - generate Z80 (MSX) binaries without optimzations.
OP.BAT          - generate 8088 (PC) binaries with optimzations.
OPZ80.BAT       - generate Z80 (MSX) binaries with optimzations.

Optimization is not assured to work on 100% of the cases, it will work
in the test program but in nothing much more harder than that.

The executables are in MS-DOS format, and you'll need

a) M80 and L80 to generate MSX binaries
b) TASM and TLINK to generate PC binaries

RBC itself can be compiled on any platform that has a decent ANSI C 
compiler, I tested it with DJGPP and gcc-linux, both compile fine.

RBC doesn't support full ANSI C features yet, it still don't have "structs" 
ans most complex addressing formats. Don't try local variables, they're
not implemented yet.

Any trouble, bug reporting or suggestions can be sent to ricardo@lsi.usp.br

Ricardo Bittencourt (27/10/97)
