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

Since the Membership card does not have disk I/O, the FORTH disk I/O routines are not expected to work.
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
* 1010_SystemsGuideToFigForth.pdf - Probably the best reference for figForth, especially for implementers.
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

If not on Windows, compile the A18 assembler for the sources in the zips/a18.zip file.

To assemble:

`a18 forth_a18.asm -l forth_a18.txt -o forth_a18.hex`

Then load the hex file onto your Membership Card with the 'L' command.  Works on [Emma 02](https://www.emma02.hobby-site.com/) as well!
