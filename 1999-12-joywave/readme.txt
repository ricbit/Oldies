                  
                              JoyWave v1.0

                Copyright (C) 1999 by Ricardo Bittencourt

---------------------------------------------------------------------------

                             Index

                         1. Introduction
                         2. Requirements
                         3. Usage
                         4. Credits

---------------------------------------------------------------------------

1. Introduction

        Hello, world.

        Everyone seems to be talking about Joynet these days.

        Joynet is a new standard for MSX communications, developed
in the international MSX mailing list. All you need to use the Joynet
is a simple cable that you can make by yourself.

        The Joynet can also be used to connect a MSX to a PC. This is great
for users that don't have a hard drive (like me), since you can use the
large storage devices of the PC to store MSX data, and upload it to the MSX
through the Joynet cable.

        This program uses the Joynet to play high-quality .WAV files in the
PCM of the MSX Turbo-R. The only limit for the size of the .WAV file
is the amount of RAM in your PC.

        Source code is included, so people who don't know how to program
the Joynet (or the MSX Turbo-R) can learn from it.

        Hope you find this program useful.

---------------------------------------------------------------------------
                                             
2. Requirements

        To use this program you will need an MSX, a PC, and a Joynet cable.

        1) the MSX must be an MSX Turbo-R in R800 mode. The Joynet cable
must be installed in joyport 1.

        2) the PC must have lots of RAM, since the .WAV file is pre-loaded
in the memory. The Joynet cable must be installed in LPT1. The uploader
run in MS-DOS, but Windows95 DOS Prompt works fine too.

        3) the Joynet cable is the standard one:

        DB-9 female             DB-25 male

             1   -----------------   2
             2   -----------------   3
             3   -----------------   4
             6   -----------------  13
             7   -----------------  12
             8   -----------------  10
             9   ----------------- 18-25

---------------------------------------------------------------------------
                                             
3. Usage

        This program plays .WAV files stored in 16000 kHz, 8-bit, mono.

        To play it, you must follow these steps IN ORDER:

        1) run the server in the PC:

                UPWAVE MUSIC.WAV

        2) run the client in the MSX:

                JOYWAVE

        The music will start right after this.

---------------------------------------------------------------------------
                                             
4. Credits

        Programming
                Ricardo Bittencourt

        Thanks to
                Takamichi Suzukawa      (for donating a Turbo-R)
                Stefan Boer             (for his PCM doc)
                Werner Kai              (for his joynet hardware description)
                Maarten ter Huurne      (for his joynet sample code)
 
        JoyVideo is coming soon.
