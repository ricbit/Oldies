                  
                  SCR2GRP v1.0 by Ricardo Bittencourt

---------------------------------------------------------------------------

                             Index

                        1. Introduction
                        2. Syntax
                        3. Example
                        4. Suggestions
                        5. Greetings
                        6. The author

---------------------------------------------------------------------------

1. Introduction

        Hello, world.

        You probably know that many of the MSX games are actually 
conversions from the ZX Spectrum. Sometimes these games have inferior
graphics than the native MSX games, but most of them are very addictive
and have great musics. 

        Unfortunately, the conversions were not always carefully done.
Some games missed a lot of details present in the Spectrum original, like
the opening screen. 

        This program was meant to be a tool for people who want to fix 
these games. Now you can use a Spectrum emulator to get a .SCR screenshot,
and use SCR2GRP to convert this image to an MSX readable format.

        The current version is compiled to MS-DOS platforms, but it 
should not be difficult to port it to other platforms. All the code is
in plain ANSI C, with minimum compiler dependencies.

        This version was compiled with DJGPP 2.0 and the executable
and source code are under GNU GPL (support free software!!)

---------------------------------------------------------------------------
                                             
2. Syntax

        The usage of SCR2GRP is very simple:

        SCR2GRP file.scr file.grp

        This command read the image "file.scr" and convert it to an
image "file.grp", meant to be displayed under SCREEN 2. 

        Please note the MSX-1 does not have all the colors of the Spectrum. 
This means some images can get wrong colors. These are the color conversions
made by the program:

        Spectrum color                  MSX color

        0  Black                        1   Black
        1  Blue                         4   Blue
        2  Red                          6   Red
        3  Magenta                      13  Magenta
        4  Green                        2   Green
        5  Cyan                         7   Cyan
        6  Yellow                       10  Yellow
        7  White                        14  Gray
        0* Bright Black                 1   Black 
        1* Bright Blue                  5   Bright Blue
        2* Bright Red                   8   Bright Red
        3* Bright Magenta               13  Magenta
        4* Bright Green                 3   Bright Green
        5* Bright Cyan                  7   Cyan
        6* Bright Yellow                11  Bright Yellow
        7* Bright White                 15  White

        The FLASH attribute is not supported.

---------------------------------------------------------------------------

3. Example

        The first thing you need is a Spectrum emulator.
        
        I suggest R80 from Raul Gomez, although it's in early stages of
development, it can already read games and save .SCR screenshots. The key
to save screenshots under R80 is "F7".

        Let's say you saved the screenshot of "Head Over Heels" into 
the file "head.scr". This file is included in this pack. To convert it
to .GRP format, you must type:

        SCR2GRP head.scr head.grp

        That's it !! To read the .GRP image in a MSX, you can use the
following BASIC program (insert this into game loaders):

        10 SCREEN 2
        20 BLOAD "file.grp",S
        30 A$=INPUT$(1)

---------------------------------------------------------------------------

4. Suggestions

        This program does everything I wanted it to do. This means I will
not make any extension to this version (unless I find some bug).
        But, with the source code, you can make improvements to the program.
Some suggestions are:

        4.1  Make a small BASIC program to reproduce the correct 
             Spectrum colors using the MSX-2 palette

        4.2  Make the program output images in Graphos III format (.SCR)

        4.3  Add support to FLASH attribute. Most probably this means
             make a small assembly program to be appended at the end of
             the .SCR image

        It would be nice if you tell me of any new version.

---------------------------------------------------------------------------

5. Greetings

        All the information needed to make this program was obtained from
the books:

        "Assembler para o TK90X" - by Maluf (the good one)
        "The MSX Red Book" - by Lars Gustav Erik Unonius

        Many thanks to the authors!!

        Thanks also to Raul Gomez and his incredible emulator R80 - it
has a very nice debugger, in the future I'll use that to convert some
missing Spectrum games to MSX...

        I also want to thanks DJ Delorie, Charles Sandmann and all the 
people behind the DJGPP project. Of course, many thanks to Richard Stallman 
and all the GNU people!! I couldn't forget the people from the international
msx mailing list, most especially Cyberknight, and remember: MSX still 
alive!!!

---------------------------------------------------------------------------

6. The author

        If you find any bug, want to make any comment, or have problems 
to understand the source code, send a e-mail to:

        ricardo@lsi.usp.br

        You can also reach me through my home page:

        http://www.lsi.usp.br/~ricardo

        Hope you find this program useful.


Ricardo Bittencourt       
