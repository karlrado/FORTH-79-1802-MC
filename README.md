# FORTH-79-1802-MC
FIG FORTH-79 Port to Lee Hart's 1802 Membership Card with MCSMP
## Purpose and Audience
The purpose of this port is to provide a FIG FORTH-79 implementation with sources
that works on the [1802 Membership Card](https://www.sunrise-ev.com/1802.htm)
equipped with the Membership Card Serial Monitor Program (MCSMP) ROM.

The initial porting effort allows:
* Relocation of the binary to either 0x0000 or 0x8000 so that it can run with either the low or high
  version of the MCSMP.
* Use of the MCSMP Facilities:
    * FORTH uses MCSMP for serial I/O
    * MCSMP starts FORTH with the RUN command
    * FORTH returns to MCSMP with the FORTH `BYE` command
    * User can debug FORTH with the MCSMP "D1" technique.
* Implementation of a "RAMDISK" to emulate the FORTH disk I/O facilities.  See below for more information.
## Sources and Credits
### A18 Assembler
Various versions of this assembler exist, but one provided by Herb Johnson works with this code.
Herb converted the sources to be compatible with
this [a18 assembler](https://www.retrotechnology.com/memship/a18.html).
A zip file containing the assembler is provided in this repository in zips/a18.zip.
### FORTH 79 sources
Herb's [page](https://www.retrotechnology.com/memship/figforth_1802.html) describes the various FORTHs for
the 1802 and the work done by various people.
The original sources are available on that page (also in this repo at zips/1802_FORTH.zip).
Herb's (perfect!) translation to a18 syntax is also on that page and can be found in this repo in zips/hart_figforth.zip.

The main source code for the port in this repository began with the `forth_a18.asm` file from the hart_figforth.zip file.
## Documentation
The docs folder in this repository contains various reference materials, collected here for convenience:
* fig_forth_installation.pdf - Probably the best reference for figForth, especially for implementers. ([source link](https://web.archive.org/web/20221113014633if_/http://archive.6502.org/books/forth_interest_group/fig_forth_installation.pdf))
* 1010_SystemsGuideToFigForth.pdf - Another useful guide for implementers.
  ([source link](https://www.forth.org/OffeteStore/1010_SystemsGuideToFigForth.pdf))
* fig-forth-glossary.txt - A great reference guide. ([source link](https://dwheeler.com/6502/fig-forth-glossary.txt))
* FORTH.ASM - Original version for TASM assembler and starting point for the A18 translation as described [here](https://www.retrotechnology.com/memship/figforth_1802.html). (extracted from 1802_FORTH.zip) ([source link](https://groups.io/g/cosmacelf/files/Forth/Fig-FORTH/1802_FORTH.zip))
* forth_doc.txt - For Mike Riley's RcForth, which isn't the same as figForth, but is still a good Forth tutorial. ([source link](https://groups.io/g/cosmacelf/files/Glenn%20Jolly/FORTH/forth_doc.txt))
* MCSMP20.pdf - User "manual" for the MCSMP. ([source link](https://www.retrotechnology.com/memship/MCSMP20.pdf))
* MCSMP20-Internal-Subroutines.pdf - Reference for MCSMP entry points. ([source link](https://groups.io/g/cosmacelf/attachment/48640/0/MCSMP20-Internal-Subroutines.pdf))
## Building
Extract the a18.exe file from the zips/a18.zip file.
It is convenient to place it in the root folder of this repository.
Or, place it anywhere on your PATH.

If not on Windows, compile the A18 assembler from the sources in the zips/a18.zip file.

The source code places FORTH at 0x8000.  If your MCSMP monitor is located at 0x8000, you'll have to edit the code
to change `RELOC` to 0x0000.

To assemble:

`a18 forth_a18.asm -l forth_a18.txt -o forth_a18.hex`

Then load the hex file onto your Membership Card with the 'L' command.
The exact details depend on what terminal emulation program you are using.
Works on [Emma 02](https://www.emma02.hobby-site.com/) as well!

## Operation
(The remainder of these instructions assume that FORTH is placed at 0x8000. 
Make the necessary adjustments if your is at 0x000.)

Start FORTH by simply using the `R8000` MCSMP command and you should see:
```
Membership Card's Serial Monitor Program Ver. 2.0A
Enter "H" for Help.
>R8000
Currently running your program

1802 FIG-FORTH R0.4  3/16/81
```

The basic FIG-FORTH vocabulary as presented in the `flig-forth-glossary.txt` file describes the FORTH words available to you.
Keep in mind that in FIG-FORTH, some of the "control" words like `IF` and `LOOP` only work in compiled words and cannot be
used on the interactive command line.

### Virtual Memory (RAMDISK), Screens, and Buffers

Since the Membership Card does not have disks for persistent storage and this FORTH model requires some sort of disk
that is addressable by sectors, this implementation provides a sort of "RAMDISK" to emulate a physical sect-addressable
disk drive.
The intent is for the user to save the contents of the RAMDISK to a file after a FORTH session, using the MCSMP "SAVE"
facility to dump the contents of the RAMDISK out to a HEX file.
Then later, if the user wishes to restore the RAMDISK to use with FORTH, they load the saved HEX file with the 
MCSMP before starting FORTH.

This implementation defines 12 1K sectors in the RAMDISK.
The RAMDISK occupies memory from 0xCD00 to 0xFCFF.
Each FORTH "Screen" is essentially the contents of a RAMDISK sector.

This implementation is compiled to dedicate space for 7 1K buffers.
I believe that these buffers are used in a LRU fashion to load disk sectors so that they can be edited and
then saved back to the disk, if desired.
It isn't clear that 7 are actually needed since the RAMDISK is fast enough.
Perhaps it is the case that someone may want to be editing up to 7 screens before being forced to dump their
current contents to disk.
In any case, the number of buffers can be easily changed, as well as the number of RAMDISK sectors.
See the program code for a memory map and definitions for the buffers and RAMDISK.

Some RAMDISK sectors are "reserved" and predefined in this implementation for convenience.  See below.
### Error Messages
Textual error messages are contained in Sector/Screen 4 and 5.  They provide a textual representation of
an error instead of a numeric error code.
If these messages are not desired, set `WARNING` to zero and then sectors 4 and 5 can be used for any purpose.
### LINE EDITOR
The FORTH "screens", seen by a command such as `7 LIST` to see the contents of sector 7 of the RAMDISK, are
much more easily edited with an EDITOR vocabulary.
The vocabulary provided by this implementation is the one presented in the `fig_forth_installation.pdf` file,
and only for the "Line Editor" functionality.
Refer to that document for more complete information.

The EDITOR definitions are in the pre-defined RAMDISK sectors 6 and 7.
The command `6 LOAD` loads the EDITOR vocabulary.

Here's part of the documentation (excerpt from the installation manual):

#### Selecting a Screen and Input of Text
To start an editing session the user types EDITOR to invoke the
appropriate vocabulary.

The screen to be edited is then selected, using either:
* n LIST ( list screen n and select it for editing ) OR
* n CLEAR ( clear screen n and select for editing )

To input new text to screen n after LIST or CLEAR the P (put)
command is used.

Example:
* 0 P THIS IS HOW
* 1 P TO INPUT TEXT
* 2 P TO LINES 0, 1, AND 2 OF THE SELECTED SCREEN.


During this description of the editor, reference is made to PAD.
This is a text buffer which may hold a line of text used by or
saved with a line editing command, or a text string to be found or
deleted by a string editing command.
PAD can be used to transfer a line from one screen to another, as
well as to perform edit operations within a single screen.

Line Editor Commands:
* n H Hold line n at PAD (used by system more often than by user),
* n D Delete line n but hold it in PAD. Line 15 becomes blank
as lines n+1 to 15 move up 1 line.
* n T Type line n and save it in PAD.
* n R Replace line n with the text in PAD.
* n I Insert the text from PAD at line n, moving the old line n
and following lines down. Line 15 is lost.
* n E Erase line n with blanks.
* n S Spread at line n. n and subsequent lines move down 1
line. Line n becomes blank. Line 15 is lost.

Perhaps String Editing will be added in the future.