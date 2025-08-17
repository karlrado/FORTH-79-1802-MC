# FORTH-79-1802-MC
FIG FORTH-79 Port to Lee Hart's 1802 Membership Card with MCSMP
## Purpose and Audience
The purpose of this port is to provide a FIG FORTH-79 implementation with sources
that works on the [1802 Membership Card](https://www.sunrise-ev.com/1802.htm)
that is equipped with the Membership Card Serial Monitor Program (MCSMP) ROM.

The main changes include:
* Able to relocate the binary so that it can run on any page boundary.
  This allows it to be relocated to 0x8000 for Membership Cards that use
  MCSMP ROM at 0x0000.
* Use the MCSMP Facilities:
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
Herb's translation to a18 syntax is also on that page and can be found in this repo in zips/hart_figforth.zip.

The main source code for the port in this repository began with the `forth_a18.asm` file from the hart_figforth.zip file.
## Building
Extract the a18.exe file from the zips/a18.zip file.
It is convenient to place it in the root folder of this repository.
Or, place it anywhere on your PATH.

To assemble:

`a18 forth_a18.asm -l forth_a18.txt -o forth_a18.hex`

Then load the hex file onto your membership card with the 'L' command.
