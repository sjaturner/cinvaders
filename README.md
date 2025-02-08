#Introduction

This is an 8080 emulator, with a twist. It emulates only enough
instructions to run Space Invaders.

It's derived from so many sources that I can only apologise if I have
missed some. This was the main inspiration:

    https://github.com/LemonBoy/Space-Invaders-Emulator

# Background

I started out in Rust, with the original idea of making a Web Assembly version.
However, the Rust implementation got a bit bogged down and, TBH, I'm
more adept at the C based bit manipulation stuff. So I thought I'd change
tack and write a C version and then re-code that in Rust. Partly to see
which was more compact and which version I thought was the most pleasing.

I'm stuck at the awkward stage where the C version works, at least as
far as I can play it and I haven't started the Rust version of this.

Also, I've already seen many nicer variations on this theme, including
Web Assembly versions that it seems a less exciting use of my spare time.

I think that Z80 was the first machine code which I used. I had a ZX81
and the opcodes were listed in the back of the spiral bound manual. I read
a few articles and was astounded at how much faster things could be made
to run. I didn't have an assembler so I'd look up the opcodes and write
them down on paper. Then put them into a BASIC program as a DATA line,
poke them into memory and jump to that using a USR command. It's a tedious
process, but it does make you thing very hard about what you are doing.

# Observations

I don't recall using BCD operations in any Z80 assembler which I wrote. To 
tell the truth, having implemented a subset of those in this program, I am  
glad I didn't. I suspect the experience would have put me off computers 
forever.

FWIW I reckon that the 6502 has a more elegant instruction set.

# Resources

This is indispensable:

    wget https://computerarcheology.com/Arcade/SpaceInvaders/Code.html 

Also, this Z80 instruction set table is lovely:

    https://clrhome.org/table/

And I have this, too:

    https://en.wikipedia.org/wiki/Programming_the_Z80:w
