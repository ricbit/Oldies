	READWAV v:0.5	

	Hello world.

	This soft allows you to play .WAV files on your MSX1, without any
additional hardware. And it's not the 1-bit PCM that everyone knows, this
one can do 4-bit PCM !!

	The input file is somewhat restricted on this version, it must be
a .WAV file of 11 kHz, mono and 8-bit quantization (these are the minimum
settings on the "Wave Studio" program that is shipped with the PC-Sound
Blaster boards). The soft doesn't check this setting, however, don't
forget to check your files before playing.

	To use the program, just copy READWAV.COM and your .WAV files to a
MSXDOS1 disk, and type "READWAV <file>". Don't use any extension, the
program will automatically add ".WAV" to your file. To play the sample
shipped in this pack, type "READWAV ELIS" (it's a very small portion of
the music "Aguas de Marco" from the brazilian singers Elis Regina and Tom
Jobim).

	I used some undocumented features of the PSG, and the only
emulator that supports it is BrMSX. The quality of the output will depend
on both the input file and the MSX used. I only tried on a brazilian
"Expert" with built-in speaker, and I get way too much noise (I hope other
computers will sound better). To get a maximum signal-to-ratio relation,
don't forget to make your input signal have maximum amplitude (without
distortion, of course). 

	The input file also must be smaller than 50kb. The next versions
will use the MEGARAM cartridge to play files as bigger as 512kb. In the
next version I will also make a 5-bit PCM (yes that is possible, without
any additional hardware). Now, I will make a study of quantization noise
on this program, and other DSP analysis, I hope the next version will
sound way better. 

	The original idea of 4-bit PCM is by Marco Antonio Simon Dal Poz
<mdalpoz@gacrux.mcca.ep.usp.br>, and the sample music was ripped from a CD
I get from Miyuki Watanabe <miki@lsi.usp.br>. The stop-drive routine is
based on an idea of Marujo <MARUJO@if.ufrgs.br>, and of course I want to
thanks Edison Pires <no e-mail yet> and Andre Delavy
<delavy@helium.fis.unb.br> (Edison for his wonderful MSX TOP SECRET book,
and Delavy for sending it to me). Finally, thanks to Cobra Software
<cobra@mandic.com.br>, who sold me a disk-drive for my MSX. Ah! I want
also to thanks Adriano Cunha <adrcunha@jaguari.dcc.unicamp.br> and
Giovanni Nunes <bitatwork@geocities.com>, just for being fudebas.



Ricardo Bittencourt
ricardo@lsi.usp.br
http://www.lsi.usp.br/~ricardo
