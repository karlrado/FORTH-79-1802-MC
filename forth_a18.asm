;
; FFFF  I   GGG        FFFF   OO   RRRR   TTTTT  H   H
; F     I  G           F     O  O  R  R     T    H   H
; FFF   I  G GGG   XX  FFF   O  O  RRR      T    HHHHH
; F     I  G   G       F     O  O  R  R     T    H   H
; F     I   GGG        F      OO   R   R    T    H   H
;
;               1   8888    00   2222
;               1   8  8   0  0     2
;               1   8888   0  0   22
;               1   8  8   0  0  2
;               1   8888    00   2222
;
;
;       ALL PUBLICATIONS OF THE FORTH INTREST GROUP
;       ARE PUBLIC DOMAIN.  THEY MAY BE FURTHER
;       DISTRIBUTED BY INCLUSION OF THIS CREDIT
;       NOTICE:
;
;       THIS PUBLICATION HAS BEEN MADE AVAILABLE BY THE
;                       FORTH INTREST GROUP
;                       P. O. BOX 1105
;                       SAN CARLOS, CA 94070
;
;       IMPLEMENTAION BY:
;               GARY R. BRADSHAW
;               RFD 1 BOX 80
;               GIDLEY ROAD
;               ESPERANCE, NY  12066
;
;       MODIFIED BY:
;               GORDEN FLEMMING
;               13490 SIMSHAW ST.
;               SYLMAR, CA  91342
;
;               JIM MCDANIEL
;               1109 POINCIANA DR.
;               SUNNYVALE, CA 94086
;;
;; Apr 2016 mods Herb Johnson for A18 cross-assembler
;; change .EQU to EQU, things like that
;
;   ADDRESS COMMENTS & CORRECTIONS TO  JIM MCDANIEL.
;
;       ACKNOWLEDGEMENTS:
;
;               KEN MANTEI
;
;               FIG INSTALLATION MANUAL
;
;               FIG 8080 ASSEMBLY SOURCE LISTING..;
;
;
;               THIS LISTING TYPED     PRINTED 3/18/81
;
;
;       THE I/O VECTORS FOR DISC  ARE POINTING TO
;       ROUTINES FOR THE RCA CDP18S007, CDP18S008
;       OR THE CDP 18SOO5..
;       FOR OTHER SYSTEMS YOU WILL NEED TO
;       CHANGE THE POINTERS AND WRITE YOUR
;       OWN ROUTINES.;
;
; THE USER VARIABLE  DV IS 3 BYTES LONG
; (USER AREA OFFSET 32H 33H 34H) AND IS USED
; TO PASS VARIABLES TO THE RCA ROM UTILITY
; WHEN CALLING FOR DISK I/O.  THE RESIDENT ROM
; UTILITIES PRODUCE THEIR OWN ERROR MESSAGES.
;
; THIS VERSION ASSEMBLES WITH START UP CONSTANTS THAT
; ASSUME 28K OF RAM. DISC BUFFERS ARE
; SET FOR 1K (THIS CAN BE EASILY CHANGED
; BY CHANGING FIRST, LIMIT, B/BUF AND B/SCR).
; BLOCK 0 BEGINS AT TRACK 0 SECTOR 1.
;
;
; DR1 (SET DRIVE TO 1) IS IMPLEMENTED AS:
;  : DR1 B/SCR 250 * OFFSET ! ;
; THERFORE B/SCR AND B/BUF CAN BE CHANGED WITHOUT
; HAVING TO REWRITE
; DR1.
; THE TERMINAL I/O ASSUMES THE USE OF AN
; RCA CDP1854 UART CONFIGURED IN ONE OF THE
; ABOVE MENTIONED SYSTEMS.  THE UART IS DRIVEN
; DIRECTLY WITHOUT CALLING RCA ROM UTILITY
; ROUTINES.
;
;
; THE FORTH WORD   MON   EXITS FORTH AND RETURNS
; TO THE RESIDENT ROM UTILITY.
;
; THE FORTH WORD  BYE  IS DEFINED AS:
; : BYE  FLUSH  MON ;;
;
;
;       REGISTER ALLOCATIONS FOR THIS VERSION
;
;               R2   RETURNS STACK POINTER  R0
;                    GROWS DOWN LEFT POINTING TO
;                    FREE LOCATION
;
;               R3   PC FOR I/O AND PRIMITIVES
;
;               R7, R8  TEMPORARY ACCUMULATORS
;
;               R9   COMPUTATION STACK POINTER   S0
;                    GROWS UPWARD
;                    LEFT POINTING AT HIGH BYTE
;
;               RA   FORTH "I" REGISTER   IP
;
;               RB   FORTH "W" REGISTER   WP
;
;               RC   PC FOR INNER INTERPRETER
;
;               RD   USER POINTER         UP
;
;               RF   DISC I/O
;
;               OTHER REGISTERS ARE LEFT AVAILABLE
;               EXCEPT THAT RF.0 IS ZERO AFTER COLD
;               OR WARM STARTS
;
;
;             MEMORY MAP
;
;       ---------------------- LIMIT
;
;            RAM BUFFERS
;
;       ---------------------- FIRST
;
;             USER AREA
;
;       ---------------------- UP
;
;            RETURN STACK      R0
;
;       ---------------------- 
;
;          TERMINAL BUFFER
;
;       ---------------------- TIB
;
;         COMPUTATION STACK
;
;       ---------------------- S0
;
;             FREE SPACE
;
;       ----------------------
;
;            TEXT BUFFER
;
;       ---------------------- PAD
;
;             WORD BUFFER
;
;       ---------------------- DP
;
;             DICTIONARY
;
;       ----------------------
;
;         BOOT UP PARAMETERS
;
;       ---------------------- ORGIN 005E
;
;          ANY REQUIRED I/O
;           INITIALIZATION
;
;       ---------------------- 0000
;
;
        INCL "1802reg.asm"
        ; Additional register definitions local to this file.
RA      EQU 10
RB      EQU 11
RC      EQU 12
RD      EQU 13
RE      EQU 14
RF      EQU 15

;
        ; RELOCATION OFFSET
        ; Set to $0000 for MC card with ROM at $8000
        ; Set to $8000 for MC card with ROM at $0000
RELOC   EQU $8000
        ; MCSMP Entry points
        ; - The NOTSCRT routines are called NOT* because they are not Standard
        IF RELOC LT $8000
MCSMPINPUT  EQU $8005
MCSMPOUTPUT EQU $821D
MCSMPOUTSTR EQU $8526
MCSMPSERIAL EQU $7FCD
NOTSCRTCALL EQU $8ADB
NOTSCRTRET  EQU $8AED
        ELSE
MCSMPINPUT  EQU $0005
MCSMPOUTPUT EQU $021D
MCSMPOUTSTR EQU $0526
MCSMPSERIAL EQU $FFCD
NOTSCRTCALL EQU $0ADB
NOTSCRTRET  EQU $0AED
        ENDI
        ;
FIRSTB  EQU $4000 + RELOC ; ADDRESS OF FIRST DISK BUFFER
LIMITB  EQU $6C2C + RELOC ; END OF DISK BUFFER AREA
CSTACK  EQU 9
RSTACK  EQU 2
	;
        ORG $0000 + RELOC
        ;
        ; SET-UP ROUTINES
        ;
        DIS
        DB $00
        ; Set up to use MCSMP
        LDI HIGH NOTSCRTCALL
        PHI R4
        LDI LOW NOTSCRTCALL
        PLO R4
        LDI HIGH NOTSCRTRET
        PHI R5
        LDI LOW NOTSCRTRET
        PLO R5
        ; Get the serial settings out of MCSMP
        LDI HIGH MCSMPSERIAL
        PHI R3
        LDI LOW MCSMPSERIAL
        PLO R3
        LDA R3
        PHI RE
        LDN R3
        PLO RE
        ; Start
        LDI HIGH START1
        PHI R3
        LDI LOW START1
        PLO R3
        SEP 3
START1: ; Send a null to get the MCSMP Q line in the right state to avoid first character corruption
        LDI 0
        PLO RB
        SEP R4
        DW MCSMPOUTPUT
        LBR START
	;
        ; "Patch" for EMIT to send a single character
        ; Code moved here only to avoid short branch issues.
CSEND1: GLO RB          ; Preserve RB  
        STR R2
        DEC R2
        INC R9
        LDN R9
        PLO RB
        SEP R4
        DW MCSMPOUTPUT
        INC R2
        LDN R2
        PLO RB
        DEC R9
        DEC R9
        DEC R9
        SEP RC
	;
        ;
        ORG $005E + RELOC
	;
START:  NOP
        LBR COLD            ; COLD START
        NOP
        LBR WARM            ; WARM START
        DW $070A            ; CPU NUMBER
        DW $0001            ; REVISION NUMBER
        DW TASK - 7         ; TOPMOST PRGM IN FORTH VOCABULARY
        DW $0008            ; BACKSPACE
        DW $2000 + RELOC    ; INITIAL USER AREA         UP
        DW $1F00 + RELOC    ; INITAL STACK              S0
        DW $1FFF + RELOC    ; INITAL RETURN STACK       R0
        DW $1F80 + RELOC    ; TERMINAL BUFFER           TIB
        DW $001F            ; NAME FIELD WIDTH          WIDTH
                            ;   (31 DECIMAL)
        DW $0000            ; WARNING                   WARNING
        DW LEND             ; FENCE                     FENCE
        DW LEND             ; INIT DICTIONARY POINTER   DP
        DW FRTH + 16        ; INIT VOCAB                VOC-LINK
	;
	;
        DB $83,"LI",$D4 ; LIT
        DW $0000
LIT:    DW $ + 2
        INC R9
        INC R9
        LDA RA
        STR R9
        INC R9
        LDA RA
        STR R9
        DEC R9
        SEP RC
	;
        ;
        ; NEXT INNER INTERPRETER
        SEP R3              ; LEAVE RC AT NEXT
NEXT:   LDA RA
        PHI RB
        LDA RA
        PLO RB
WBR:    LDA RB
        PHI R3
        LDA RB
        PLO R3
        BR NEXT - 1
        ; EXECUTE
        DB $87,"EXECUT",$C5 ; EXECUTE
	DW LIT - 6
EXE:    DW $ + 2
        LDA R9
        PHI RB
        LDN R9              ; LOAD W FROM STACK              
        PLO RB
        DEC R9
        DEC R9
        DEC R9
        INC RC
        INC RC
        INC RC              ; POINT TO WBR
        INC RC
        SEP RC
	;
	;
        DB $86,"BRANC",$C8 ; BRANCH
        DW EXE - 10
BRCH:   DW $ + 2
BRANCH: LDA RA
        STR R2
        LDA RA
        PLO RA
        LDN R2
        PHI RA
        SEP RC
	;
	;
        DB $87,"0BRANC",$C8 ; 0BRANCH
	DW BRCH - 9
ZBRCH:  DW $ + 2
        LDA R9
        BNZ NO
        LDN R9
        BNZ NO
        DEC R9
        DEC R9
        DEC R9
        BR BRANCH
NO:     INC RA
        INC RA
        DEC R9
        DEC R9
        DEC R9
        SEP RC
	;
        DB $86,"(LOOP",$A9 ; (LOOP)
        DW ZBRCH - 10
LUPE:   DW $ + 2
        INC R2
        GHI R2
        PHI R8
        PHI R7
        GLO R2
        PLO R8
        PLO R7
        DEC R2
        LDN R8
        ADI $01
        STR R8
        INC R8
        LDN R8
        ADCI $00
        NOP                 ; TO NEW PAGE
        NOP
COMP:   STR R8
        INC R8
        SEX R7
        LDA R8
        SD
        INC R7
        LDN R8
        SDB
        ANI $80
        BZ CEND
        LDA RA
        STR R2
        LDN RA
        PLO RA
        LDN R2
        PHI RA
        SEP RC
CEND:   INC RA
        INC RA
        INC R2
        INC R2
        INC R2
        INC R2
        SEP RC
	;
        DB $87,"(+LOOP",$A9 ; (+LOOP)
	  DW LUPE - 9
PLUPE:  DW $ + 2
        INC R2
        GHI R2
        PHI R8
        PHI R7
        GLO R2
        PLO R8
        PLO R7
        DEC R2
        SEX R9
        INC R9
        LDN R8
        ADD
        STR R8
        INC R8
        DEC R9
        LDN R8
        ADC
        STR R8
        LDN R9
        SHL
        DEC R9
        DEC R9
        BDF LUPE1
        BR COMP +1
LUPE1:  INC R8
        SEX R7
        LDA R8
        SM
        INC R7
        LDN R8
        SMB
        BR COMP + 8
	;
	;
        DB $84,"(DO",$A9 ; (DO)
        DW PLUPE - 10
PDO:    DW $ + 2
        DEC R9
        DEC R9
        SEX R2
        LDA R9
        STXD
        LDA R9
        STXD
        LDA R9
        STXD
        LDN R9
        STXD
        DEC R9
        DEC R9
        DEC R9
        DEC R9
        DEC R9
        SEP RC
	;
	;
        DB $85,"DIGI",$D4 ; DIGIT
        DW PDO - 7
DGT:    DW $ + 2
        SEX R9
        DEC R9
        LDN R9
        SMI $30
        BNF BAD
        SMI $11
        BDF DOK
        SMI $F9
        BDF BAD
DOK:    ADI $0A
        STR R9
        INC R9
        INC R9
        SM
        BDF BAD2
        DEC R9
        SEP RC
BAD2:   DEC R9
        DEC R9
BAD:    LDI $00
        STXD
        STR R9
        SEP RC
	;
        DB $86,"(FIND",$A9 ; (FIND)
        DW DGT - 8
FIND:   DW $ + 2
        DEC R9
        DEC R9
        LDA R9
        PHI R8
        LDA R9
        PLO R8
        LDA R9
        PHI R7
        LDN R9
        PLO R7
        DEC R9
        DEC R9
LOOP1:  SEX R7              ; SAVE LENGTH BYTE
        LDN R7
        STR R2
        LDA R8              ; COMPARE LENGTH BYTES
        XOR
        ANI $3F
        BNZ BADLEN
NEXCHR: INC R7
        LDA R8              ; COMPARE NEXT CHARACTER
        XOR
        SHL
        BNZ BADCHR          ; NO MATCH ON 7 BITS
        SHLC
        BZ NEXCHR           ; IF NOT LAST CHARACTER
LOOP2:  LDA R7              ;   ELSE END OF STRING
        ANI $80
        BZ LOOP2
        SEX R9              ; END OF DICT NAME
        GLO R7
        ADI $04
        STXD
        GHI R7
        ADCI $00
        STR R9              ; LEAVE PFA
        INC R9
        INC R9
        LDI $00
        STR R9
        INC R9
        LDN R2              ; GET LENGTH BYTE
        STR R9
        INC R9
        LDI $FF
        STR R9
        INC R9
        STXD                ; AND TRUE FLAG
        SEP RC
BADLEN: INC R7
BADCHR: LDA R7
        ANI $80
        BZ BADCHR
        LDN R7
        BNZ BOK
        INC R7
        LDN R7
        DEC R7
        BNZ BOK
        LDI $00            ; LINK=0 RETURN FALSE
        STR R9
        DEC R9
        STR R9
        SEP RC
BOK:    LDA R7
        STR R2
        LDN R7
        PLO R7
        LDN R2
        PHI R7
        LDN R9
        PLO R8
        DEC R9
        LDA R9
        PHI R8
        BR LOOP1
	;
	;
        DB $87,"ENCLOS",$C5 ; ENCLOSURE
	DW FIND -9
ENCL:   DW $ + 2
        DEC R9
        DEC R9
        LDA R9
        PHI R8
        LDA R9
        PLO R8
        INC R9
        LDI $00            ; R7.0 IS OFFSET
        PLO R7
        LDN R9              ; SAVE DELIM
        STR R2
        SEX R2
LOP1:   LDN R8
        SM
        BNZ FRST            ; FIND FIRST NON-
        INC R8              ;   DELIM CHAR
        INC R7
        BR LOP1
FRST:   GLO R7              ; SAVE OFFSET TO
        STR R9
        PHI R7
        INC R9              ;   FIRST CHARACTER
        LDI $00
        STR R9
        INC R9
        INC R9
        STR R9
        INC R9
LOP2:   LDN R8
        BZ NULL             ; EQUAL NULL ?
        SM                  ; SUBTRACT DELIMIN
        BZ DELIM
        INC R8
        INC R7
        BR LOP2
NULL:   GLO R7              ; LEAVE OFFSET
        SEX R9
        STR R9
        GHI R7              ; TO NEXT CHARACTER
        SM
        BNZ SKIP
        INC R7
SKIP:   GLO R7              ; LAST CHARACTER IN
        DEC R9
        DEC R9
        STR R9              ; WORD
        INC R9
        SEP RC
DELIM:  INC R7
        GLO R7
        STR R9
        DEC R7
        BR SKIP
	;
        DB $85,"CMOV",$C5 ; CMOVE
        DW ENCL - 10
CMOVE:  DW $ + 2
        LDA R9
        ADI $01
        PHI R7
        LDN R9
        PLO R7
        DEC R7
        DEC R9
        DEC R9
        DEC R9
        GHI RA              ; PUSH RA
        STR R2
        DEC R2
        GLO RA
        STR R2
        LDA R9              ; RA IS "TO"
        PHI RA
        LDN R9
        PLO RA
        DEC R9
        DEC R9
        DEC R9
        LDA R9              ; R8 IS "FROM"
        PHI R8
        LDN R9
        PLO R8
        DEC R9
        DEC R9
        DEC R9
LUUP:   GHI R7
        BZ END2
        LDA R8
        STR RA
        INC RA
        DEC R7
        BR LUUP
END2:   LDA R2              ; POP RA
        PLO RA
        LDN R2
        PHI RA
        SEP RC
	;
        DB $82,$55,$AA  ; U*
                            ; UNSIGNED 16 X 16 BIT MULTIPLY
        DW CMOVE - 8
USTAR:  DW $ + 2
        SEX R9
        LDI R0
        PLO R7              ; R7 IS LOW 2 BYTES
        PHI R7
        LDI $10            ; OF PRODUCT
LP7B:   STR R2              ; MEM(2) IS LOOP COUNT
        GLO R7
        SHL
        PLO R7
        GHI R7
        SHLC
        PHI R7
        INC R9              ; DOUBLE THE PRODUCT AND
        LDN R9              ;   TEST HIGH BIT
        SHLC
        STXD
        LDN R9              ;   OF OP2
        SHLC
        STR R9
        BNF SKP9A
        DEC R9
        GLO R7
        ADD
        PLO R7
        DEC R9              ;   ADD OP1
        GHI R7
        ADC
        PHI R7
        INC R9              ; TO 24 BIT PRODUCT
        INC R9
        INC R9
        LDI $00
        ADC
        STXD
SKP9A:  LDN R2
        SMI $01
        BNZ LP7B
UOUT:   DEC R9              ; MOVE REST OF
        GLO R7
        STXD
        GHI R7              ; PRODUCT TO STACK
        STR R9
        INC R9
        INC R9
        SEP RC
	;
        DB $82,$55,$AF  ; U/ UNSIGNED DIVIDE
        DW USTAR - 5
USLSH:  DW $ + 2
        SEX R9
        DEC R9
        DEC R9
        LDA R9
        PHI R7
        LDN R9
        PLO R7
        DEC R9
        DEC R9
        LDA R9
        SHL
        INC R9
        STXD
        DEC R9
        DEC R9
        LDA R9
        SHLC
        INC R9
        STR R9
        INC R9
        LDI $10
        PLO R8
LPC5:   GLO R7
        SHLC
        PLO R7
        GHI R7
        SHLC
        PHI R7
        INC R9
        INC R9
        GLO R7
        SM
        PHI R8
        DEC R9
        GHI R7
        SMB
        BNF SKPD8
        PHI R7
        GHI R8
        PLO R7
SKPD8:  DEC R9
        LDN R9
        SHLC
        STXD
        LDN R9
        SHLC
        STR R9
        INC R9
        DEC R8
        GLO R8
        BNZ LPC5
        DEC R9
        BR UOUT
	;
        DB $83,"AN",$C4  ; AND
        DW USLSH - 5
FAND:   DW $ + 2
        GLO R9
        PLO R8
        GHI R9
        PHI R8
        DEC R8
        SEX R8
        INC R9
        LDN R9
        AND
        STXD
        DEC R9
        LDN R9
        AND
        STR R8
        DEC R9
        DEC R9
        SEP RC
	;
        DB $82,$4F,$D2  ; OR
        DW FAND - 6
FFOR:   DW $ + 2
        GLO R9
        PLO R8
        GHI R9
        PHI R8
        DEC R8
        SEX R8
        INC R9
        LDN R9
        OR
        STXD
        DEC R9
        LDN R9
        OR
        STR R8
        DEC R9
        DEC R9
        SEP RC
	;
        DB $83,"XO",$D2   ; XOR
        DW FFOR - 5
FXOR:   DW $ + 2
        GLO R9
        PLO R8
        GHI R9
        PHI R8
        DEC R8
        SEX R8
        INC R9
        LDN R9
        XOR
        STXD
        DEC R9
        LDN R9
        XOR
        STR R8
        DEC R9
        DEC R9
        SEP RC
	;
        DB $83,"SP",$C0  ; SP@
        DW FXOR - 6
FSPAT:  DW $ + 2
        GHI R9
        STR R2
        GLO R9
        INC R9
        INC R9
        INC R9
        STR R9
        DEC R9
        LDN R2
        STR R9
        SEP RC
	;
        DB $83,"SP",$A1  ; SP!
                            ;   stack pointer store
        DW FSPAT - 6
SP1:    DW $ + 2
        GLO RD
        ADI $06
        PLO R8
        GHI RD
        ADCI $00
        PHI R8
        LDA R8
        PHI R9
        LDN R8
        PLO R9
        SEP RC
	;
        DB $83,"RP",$A1  ; RP!
                            ; RETURN STACK POINTER STORE
        DW SP1 - 6
RP1:    DW $ + 2
        GLO RD
        ADI $08  ; Offset of initial Return stack pointer in USER
        PLO R8
        GHI RD
        ADCI $00
        PHI R8
        LDA R8
        PHI R2
        LDN R8
        PLO R2
        SEP RC
	;
        DB $82,$3B,$D3  ; S (UNEST)
        DW RP1 - 6
SEMIS:  DW $ + 2
        INC R2
        LDA R2
        PLO RA
        LDN R2
        PHI RA
        SEP RC

        DB $85,"LEAV",$C5 ; LEAVE
        DW SEMIS - 5
LVE:    DW $ + 2
        GHI R2
        PHI R8
        GLO R2
        PLO R8
        INC R8
        LDA R8
        INC R8
        STR R8
        DEC R8
        LDA R8
        INC R8
        STR R8
        SEP RC
	;
        DB $82,$3E,$D2  ; >R   TO R
        DW LVE - 8
GR:     DW $ + 2
        SEX R2
        LDA R9
        STXD
        LDN R9
        STXD
        DEC R9
        DEC R9
        DEC R9
        SEP RC
	;
        DB $82,$52,$BE  ; R>   FROM R
        DW GR - 5
RG:     DW $ + 2
        INC R9
        INC R9
        INC R9
        INC R2
        LDA R2
        STR R9
        DEC R9
        LDN R2
        STR R9
        SEP RC
	;
        DW $81D2          ; R   COPY TOP OF RETN
        DW RG - 5          ; STACK TO TOP OF
R:      DW $ + 2           ; COMPUTATION STACK
        GLO R2
        PLO R8
        GHI R2
        PHI R8
        INC R8
        INC R9
        INC R9
        INC R9
        LDA R8
        STR R9
        DEC R9
        LDN R8
        STR R9
        SEP RC
	;
        DB $82,$30,$BD  ; 0=
        DW R - 4
ZEQAL:  DW $ + 2
        LDA R9
        BNZ NONE
        LDN R9
        BNZ NONE
ZONE:   LDI $01
        BR STOR
NONE:   LDI $00
STOR:   STR R9
        DEC R9
        LDI $00
        STR R9
        SEP RC
	;
        DB $82,$30,$BC  ; 0<
        DW ZEQAL - 5
ZLESS:  DW $ + 2
        LDA R9
        SHL
        BDF ZONE
        BR NONE
	;
        DW $81AB          ; +
        DW ZLESS - 5
PLUS:   DW $ + 2
        GLO R9
        PLO R8
        GHI R9
        PHI R8
        DEC R8
        SEX R8
        INC R9
        LDN R9
        ADD
        STXD
        DEC R9
        LDN R9
        ADC
        STR R8
        DEC R9
        DEC R9
        SEP RC
	;
        DB $85,"MINU",$D3 ; MINUS
        DW PLUS - 4
MINUS:  DW $ + 2
        SMI $00            ; SET CARRY
MINOS:  INC R9
        LDN R9
        XRI $FF
        ADCI $00
        STR R9
        DEC R9
        LDN R9
        XRI $FF
        ADCI $00
        STR R9
        SEP RC
	;
        DB $82,$44,$AB  ; D+ DBL PRCN INTEGERS
        DW MINUS - 8       ; ARE STORED HIGH 16 BITS TOP
DPLUS:  DW $ + 2           ; LOW 16 BITS BENEATH
        GLO R9
        SMI $05
        PLO R8
        GHI R9
        SMBI $00
        PHI R8
        DEC R9
        SEX R8
        LDN R9
        ADD
        STXD
        DEC R9
        LDN R9
        ADC
        STR R8
        INC R8
        INC R8
        INC R8
        INC R9
        INC R9
        INC R9
        LDN R9
        ADC
        STXD
        DEC R9
        LDN R9
        ADC
        STR R8
        DEC R9
        DEC R9
        DEC R9
        DEC R9
        SEP RC
	;
        DB $86,"DMINU",$D3 ; DMINUS
        DW DPLUS - 5
DMIN:   DW $ + 2
        SEX R9
        DEC R9
        LDN R9
        XRI $FF
        ADI $01
        STXD
        LDN R9
        XRI $FF
        ADCI $00
        STR R9
        INC R9
        INC R9
        BR MINOS
	;
        DB $84,"OVE",$D2 ; OVER
        DW DMIN - 9
OVER:   DW $ + 2
        DEC R9
        DEC R9
        LDA R9
        INC R9
        INC R9
        INC R9
        STR R9
        DEC R9
        DEC R9
        DEC R9
        LDA R9
        INC R9
        INC R9
        INC R9
        STR R9
        DEC R9
        SEP RC
	;
        DB $84,"DRO",$D0 ; DROP
        DW OVER - 7
DROP:   DW $ + 2
        DEC R9
        DEC R9
        SEP RC
	;
        DB $84,"SWA",$D0 ; SWAP
        DW DROP - 7
SWAP:   DW $ + 2
        GLO R9
        PLO R8
        GHI R9
        PHI R8
        DEC R8
        LDN R8
        STR R2
        INC R9
        LDN R9
        STR R8
        LDN R2
        STR R9
        DEC R9
        DEC R8
        LDN R8
        STR R2
        LDN R9
        STR R8
        LDN R2
        STR R9
        SEP RC
	;
        DB $83,"DU",$D0  ; DUP
        DW SWAP - 7
DUP:    DW $ + 2
        LDA R9
        INC R9
        STR R9
        DEC R9
        LDA R9
        INC R9
        STR R9
        DEC R9
        SEP RC
	;
        DB $82,$2B,$A1  ; +!
        DW DUP - 6
PLUSS:  DW $ + 2
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        DEC R9
        DEC R9
        INC R8
        SEX R8
        LDN R9
        ADD
        STXD
        DEC R9
        LDN R9
        ADC
        STR R8
POP:    DEC R9
        DEC R9
        SEP RC
	;
        DB $86,"TOGGL",$C5 ; TOGGLE
        DW PLUSS - 5
TGLE:   DW $ + 2
        INC R9
        LDN R9
        PLO R7
        DEC R9
        DEC R9
        DEC R9
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        SEX R8
        GLO R7
        XOR
        STR R8
        DEC R9
        BR POP
        ;        
        DW $81C0          ; @
        DW TGLE - 9
AT:     DW $ + 2
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        DEC R9
        LDA R8
        STR R9
        INC R9
        LDN R8
        STR R9
        DEC R9
        SEP RC
	;
        DB $82,$43,$C0  ; C@
        DW AT - 4
CAT:    DW $ + 2
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        LDN R8
        STR R9
        DEC R9
        LDI $00
        STR R9
        SEP RC
	;
        DW $81A1          ; !   STORE
        DW CAT - 5
EX:     DW $ + 2
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        DEC R9
        DEC R9
        DEC R9
        LDA R9
        STR R8
        INC R8
        LDN R9
        STR R8
        DEC R9
        DEC R9
        DEC R9
        SEP RC
	;
        DB $82,$43,$A1  ; C!   C STORE
        DW EX - 4
CEX:    DW $ + 2
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        DEC R9
        DEC R9
        LDN R9
        STR R8
        DEC R9
        DEC R9
        DEC R9
        SEP RC
;
;
; THE FOLLOWING FOUR ROUTINES ARE USER DEFINED
; FOR THE CONSULE INPUT AND OUTPUT       
        ;
        ; SEND ASCII TO TERMINAL
        ;
        DB $84,"EMI",$D4 ; EMIT
        DW CEX - 5
EMIT:   DW NEST            ; OUTPUT CHAR TO
                            ; TERMINAL AND INCREMENT
                            ; "OUT"
        DW FOUT            ; GET ADDRESS OF OUT
        DW CSEND
        DW SEMIS
CSEND:  DW $ + 2
; INCREMENT USER VARIABLE "OUT"
; WHOSE ADDRESS IN ON THE COMPUTATION
; STACK
        LDA R9
        PHI R8
        LDN R9
        PLO R8
        DEC R9
        DEC R9
        DEC R9
        INC R8
        LDN R8
        ADI $01
        STR R8
        DEC R8
        LDN R8
        ADCI $00
        STR R8
; SEND OUT CHARACTER WHICH IS ON
; THE COMP.STACK
; Move this code to avoid short branch across page boundaries.
        LBR CSEND1
	;
        ;
        DB $83,"KE",$D9  ; KEY   READ KEYBOARD
        DW EMIT - 7
KEY:    DW $ + 2
        INC R9
        INC R9
        INC R9  ; Bump to low byte of stack item to return char
        GLO RB  
        STR R2  ; Save RB.0 on return stack (Let MCSMP do SEX R2)
        DEC R2
        SEP R4
        DW MCSMPINPUT
        GLO RB
        ANI $7F
        STR R9  ; Store character in low byte of return word
        DEC R9  
        LDI $00
        STR R9  ; High byte of returned item 
        INC R2  ; Restore RB.0
        LDN R2
        PLO RB
        SEP RC
        ;
        ; TEST FOR BREAK
        ;
        DB $89,"?TERMINA",$CC ; ?TERMINAL
	DW KEY - 6
; ASSUME THAT A FRAMING ERROR INDICATES
; THAT THE BREAK KEY IS OR WAS PRESSED.
; This is now a NOOP for MC
QTERM:  DW $ + 2
        SEX CSTACK
        IRX
        IRX
        IRX
        ; Store a 0 for framing error bit instead of reading it from UART
        LDI $00
        STXD
        STR CSTACK
        SEP RC
        ;
        ; SEND CR/LF TO TERMINAL
        ;
        DB $82,$43,$D2  ; CR
        DW QTERM - 12
CR:     DW $ + 2
        GLO RB          ; Preserve RB
        STR R2
        DEC R2
        LDI $0D
        PLO RB
        SEP R4
        DW MCSMPOUTPUT
        LDI $0A
        PLO RB
        SEP R4
        DW MCSMPOUTPUT
        INC R2
        LDN R2
        PLO RB
        SEX R9
        SEP RC
; Avoid short branch across page boundaries.
; The original address for NEST is x5c2.
        DB 0,0,0,0,0,0,0,0,0,0,0
        ;
        ;
NEST:   GHI RA
        STR R2
        DEC R2
        GLO RA
        STR R2
        DEC R2
        GHI RB
        PHI RA
        GLO RB
        PLO RA
        SEP RC
        ;
VAR:    INC R9
        INC R9
        GHI RB
        STR R9
        INC R9
        GLO RB
        STR R9
        DEC R9
        SEP RC
        ;
CONST:  INC R9
        INC R9
        LDA RB
        STR R9
        INC R9
        LDA RB
        STR R9
        DEC R9
        SEP RC
        ;
USER:   INC R9
        INC R9
        SEX R9
        LDA RB
        STR R9
        INC R9
        LDA RB
        STR R9
        GLO RD
        ADD
        STXD
        GHI RD
        ADC
        STR R9
        SEP RC
;
; FROM HERE ON THE SOURCE IS GENERALLY
; DEFINED WITH FORTH WORD ADDRESSES
;
        DW $81B0          ; 0
        DW CR - 5
ZERO:   DW CONST
        DW $0000
        ;
        DW $81B1          ; 1
        DW ZERO - 4
ONE:    DW CONST
        DW $0001
        ;
        DW $81B2          ; 2
        DW ONE - 4
TWO:    DW CONST
        DW $0002
        ;
        DB $82,$42,$CC  ; BL
        DW TWO - 4         ; CONSTANT ASCII BLANK
BL:     DW CONST
        DW $0020
        ;
        DB $83,$43,$2F,$CC ; C/L
                                ; CHARACTERS PER LINE
        DW BL - 5
CL:     DW CONST
        DW $0040          ; 64 (DECIMAL)
        ;
        DB $85,"FIRS",$D4 ; FIRST
        DW CL - 6
FIRST:  DW CONST
        DW FIRSTB
        ;
        DB $85,"LIMI",$D4 ; LIMIT
        DW FIRST - 8
LIMIT:  DW CONST
        DW LIMITB
        ;
        DB $85,"B/BU",$C6 ; B/BUF
	                       ; BYTES PER BUFFER
        DW LIMIT - 8
BBUF:   DW CONST
        DW $0400          ; 1024 BYTES/BUFFER
        ;
        DB $85,"B/SC",$D2 ; B/SCR
	                       ; BUFFERS/SCREEN
        DW BBUF - 8
BSCR:   DW CONST
        DW $0001
        ;
        DB $86,"ORIGI",$CE ; ORIGIN
        DW BSCR - 8
ORGN:   DW CONST
        DW START
        ;
        DB $87,"+ORIGI",$CE ; +ORIGIN

        DW ORGN - 9
PORGN:  DW NEST
        DW ORGN
        DW PLUS
        DW SEMIS
        ;
        ; USER VARIABLES
        ;
        DB $82,$53,$B0  ; S0
        DW PORGN - 10
SO:     DW USER
        DW $0006
        ;
        DB $82,$52,$B0  ; R0
        DW SO - 5
RO:     DW USER
        DW $0008
        ;
        DB $83,"TI",$C2  ; TIB
        DW RO - 5
TIB:    DW USER
        DW $000A
        ;
        DB $85,"WIDT",$C8 ; WIDTH
        DW TIB - 6
WIDTH:  DW USER
        DW $000C
        ;
        DB $87,"WARNIN",$C7 ; WARNING
	DW WIDTH - 8
WRNG:   DW USER
        DW $000E
        ;
        DB $85,"FENC",$C5 ; FENCE   FORGET BOUNDRY
        DW WRNG - 10
FNCE:   DW USER
        DW $0010
        ;
        DB $82,$44,$D0  ; DP
        DW FNCE - 8
DP:     DW USER
        DW $0012
        ;
        DB $88,"VOC-LIN",$CB ; VOC-LINK
	DW DP - 5
VL:     DW USER
        DW $0014
        ;
        DB $83,$42,$4C,$CB ; BLK
        DW VL - 11
BLK:    DW USER
        DW $0016
        ;
        DB $82,$49,$CE  ; IN
        DW BLK - 6
FIN:    DW USER
        DW $0018
        ;
        DB $83,"OU",$D4  ; OUT
        DW FIN - 5
FOUT:   DW USER
        DW $001A
        ;
        DB $83,"SC",$D2  ; SCR
        DW FOUT - 6
FSCR:   DW USER
        DW $001C
        ;
        DB $86,"OFFSE",$D4 ; OFFSET
        DW FSCR - 6
OFST:   DW USER
        DW $001E
        ;
        DB $87,"CONTEX",$D4 ; CONTEXT
	DW OFST - 9
CNTX:   DW USER
        DW $0020
        ;
        DB $87,"CURREN",$D4 ; CURRENT
	DW CNTX - 10
CRNT:   DW USER
        DW $0022
        ;
        DB $85,"STAT",$C5 ; STATE
        DW CRNT - 10
STT:    DW USER
        DW $0024
        ;
        DB $84,"BAS",$C5 ; BASE
        DW STT - 8
BASE:   DW USER
        DW $0026
        ;
        DB $83,$44,$50,$CC ; DPL
        DW BASE - 7
DPL:    DW USER
        DW $0028
        ;
        DB $83,$46,$4C,$C4 ; FLD
        DW DPL - 6
FLD:    DW USER
        DW $002A
        ;
        DB $83,$43,$53,$D0 ; CSP
        DW FLD - 6
CSP:    DW USER
        DW $002C
        ;
        DB $82,$52,$A3  ; R#
        DW CSP - 6
RNU:    DW USER
        DW $002E
        ;
        DB $83,$48,$4C,$C4 ; HLD
        DW RNU - 5
HLD:    DW USER
        DW $0030
        DB $82,$44,$D6  ; DV
        DW HLD - 6         ; 3 BYTE VECTOR AREA
; USED DURING DISK OPERATIONS
DV:     DW USER
        DW $0032
        ;
        ; END OF USER VARIABLES
        ;
        DB $82,$31,$AB  ; 1+
        DW DV - 5
PLUS1:  DW NEST
        DW ONE
        DW PLUS
        DW SEMIS
        ;
        DB $82,$32,$AB  ; 2+
        DW PLUS1 - 5
PLUS2:  DW NEST
        DW TWO
        DW PLUS
        DW SEMIS
        ;
        DB $84,"HER",$C5 ; HERE
        DW PLUS2 - 5
HERE:   DW NEST
        DW DP
        DW AT
        DW SEMIS
        ;
        DB $85,"ALLO",$D4 ; ALLOT
        DW HERE - 7
ALLOT:  DW NEST
        DW DP
        DW PLUSS
        DW SEMIS
        ;
        DW $81AC          ; , (COMMA)
        DW ALLOT - 8
COMMA:  DW NEST
        DW HERE
        DW EX
        DW TWO
        DW ALLOT
        DW SEMIS
        ;
        DB $82,$43,$AC  ; C,
        DW COMMA - 4
CCMA:   DW NEST
        DW HERE
        DW CEX
        DW ONE
        DW ALLOT
        DW SEMIS
        ;
        DW $81AD          ; - (MINUS SIGN)
        DW CCMA - 5
MINS:   DW NEST
        DW MINUS
        DW PLUS
        DW SEMIS
        ;
        DW $81BD          ; = (EQUAL SIGN)
        DW MINS - 4
EQL:    DW NEST
        DW MINS
        DW ZEQAL
        DW SEMIS
        ;
        DW $81BC          ; < (LESS THAN SIGN)
        DW EQL - 4
LESS:   DW NEST
        DW MINS
        DW ZLESS
        DW SEMIS
        ;
        DW $81BE          ; > (GTR THAN SIGN)
        DW LESS - 4
GTR:    DW NEST
        DW SWAP
        DW LESS
        DW SEMIS
        ;
        DB $83,$52,$4F,$D4 ; ROT
        DW GTR - 4
ROT:    DW NEST
        DW GR
        DW SWAP
        DW RG
        DW SWAP
        DW SEMIS
        ;
        DB $85,"SPAC",$C5 ; SPACE
        DW ROT - 6
SPC:    DW NEST
        DW BL
        DW EMIT
        DW SEMIS
        ;
        DB $84,"-DU",$D0 ; -DUP
        DW SPC - 8
MDUP:   DW NEST
        DW DUP
        DW ZBRCH
        DW $ + 4
        DW DUP
        DW SEMIS
        ;
        DB $88,"TRAVERS",$C5 ; TRAVERSE
	DW MDUP - 7
TRVS:   DW NEST
        DW SWAP
TR1:    DW OVER
        DW PLUS
        DW LIT
        DW $007F
        DW OVER
        DW CAT
        DW LESS
        DW ZBRCH
        DW TR1
        DW SWAP
        DW DROP
        DW SEMIS
        ;
        ;
        DB $86,"LATES",$D4 ; LATEST
        DW TRVS - 11
LTST:   DW NEST
        DW CRNT
        DW AT
        DW AT
        DW SEMIS
        ;
        ;
        DB $83,$4C,$46,$C1 ; LFA
        DW LTST - 9        ; LINK FIELD ADDRESS
LFA:    DW NEST
        DW LIT
        DW $0004
        DW MINS
        DW SEMIS
        ;
        DB $83,$43,$46,$C1 ; CFA
        DW LFA - 6         ; CODE FIELD ADDRESS
CFA:    DW NEST
        DW TWO
        DW MINS
        DW SEMIS
        ;
        ;
        DB $83,$4E,$46,$C1 ; NFA
        DW CFA - 6         ; NAME FIELD ADDRESS
NFA:    DW NEST
        DW LIT
        DW $0005
        DW MINS
        DW LIT
        DW $FFFF
        DW TRVS
        DW SEMIS
        ;
        ;
        DB $83,$50,$46,$C1 ; PFA
        DW NFA - 6         ; PARAMETER FIELD ADDRESS
PFA:    DW NEST
        DW ONE
        DW TRVS
        DW LIT
        DW $0005
        DW PLUS
        DW SEMIS
        ;
        ;
        DB $84,$21,$43,$53,$D0 ; !CSP
        DW PFA - 6
DCSP:   DW NEST
        DW FSPAT
        DW CSP
        DW EX
        DW SEMIS
        ;
        ;
        DB $86,"?ERRO",$D2 ; ?ERROR
        DW DCSP - 7
QERR:   DW NEST
        DW SWAP
        DW ZBRCH
        DW $ + 8
        DW ERROR
        DW BRCH
        DW $ + 4
        DW DROP
        DW SEMIS
        ;
        ;
        DB $85,"?COM",$D0 ; ?COMP
        DW QERR - 9
QCMP:   DW NEST
        DW STT
        DW AT
        DW ZEQAL
        DW LIT
        DW $0011
        DW QERR
        DW SEMIS
        ;
        ;
        DB $85,"?EXE",$C3 ; ?EXEC
        DW QCMP - 8
EXC:    DW NEST
        DW STT
        DW AT
        DW LIT
        DW $0012
        DW QERR
        DW SEMIS
        ;
        ;
        DB $86,"?PAIR",$D3 ; ?PAIRS
        DW EXC - 8
QPR:    DW NEST
        DW MINS
        DW LIT
        DW $0013
        DW QERR
        DW SEMIS
        ;
        ;
        DB $84,$3F,$43,$53,$D0 ; ?CSP
        DW QPR - 9
QCSP:   DW NEST
        DW FSPAT
        DW CSP
        DW AT
        DW MINS
        DW LIT
        DW $0014
        DW QERR
        DW SEMIS
        ;
        ;
        DB $88,"?LOADIN",$C7 ; ?LOADING

        DW QCSP - 7
QLDG:   DW NEST
        DW BLK
        DW AT
        DW ZEQAL
        DW LIT
        DW $0016
        DW QERR
        DW SEMIS
        ;
        ;
        DB $87,"COMPIL",$C5 ; COMPILE
	DW QLDG - 11
CMPL:   DW NEST
        DW QCMP
        DW RG
        DW DUP
        DW PLUS2
        DW GR
        DW AT
        DW COMMA
        DW SEMIS
        ;
	;
        DW $C1DB          ; [   LEFT BRACKET
        DW CMPL - 10
LB:     DW NEST
        DW ZERO
        DW STT
        DW EX
        DW SEMIS
        ;
        ;
        DW $81DD          ; ]   RIGHT BRACKET
        DW LB - 4
RBK:    DW NEST
        DW LIT
        DW $00C0
        DW STT
        DW EX
        DW SEMIS
        ;
        ;
        DB $86,"SMUDG",$C5 ; SMUDGE
        DW RBK - 4
SMDG:   DW NEST
        DW LTST
        DW LIT
        DW $0020
        DW TGLE
        DW SEMIS
        ;
        ;
        DB $83,$48,$45,$D8 ; HEX
        DW SMDG - 9
MHEX:   DW NEST
        DW LIT
        DW $0010
        DW BASE
        DW EX
        DW SEMIS
        ;
        ;
        DB $87,"DECIMA",$CC ; DECIMAL
        DW MHEX - 6
MDCML:  DW NEST
        DW LIT
        DW $000A
        DW BASE
        DW EX
        DW SEMIS
        ;
        ;
        DB $87,"(;CODE",$A9 ; (;CODE)
        DW MDCML - 10
PCODE:  DW NEST
        DW RG
        DW LTST
        DW PFA
        DW CFA
        DW EX
        DW SEMIS
        ;
        ;
        DB $C5,";COD",$C5 ; ;CODE (IMMEDIATE)
        DW PCODE - 10
CODE:   DW NEST
        DW QCSP
        DW CMPL
        DW PCODE
        DW LB
        DW SMDG
        DW SEMIS
        ;
        ;
        DB $85,"COUN",$D4 ; COUNT
        DW CODE - 8
CNT:    DW NEST
        DW DUP
        DW PLUS1
        DW SWAP
        DW CAT
        DW SEMIS
        ;
        ;
        DB $84,"TYP",$C5 ; TYPE
        DW CNT - 8
TYPE:   DW NEST
        DW MDUP
        DW ZBRCH
        DW $ + 24
        DW OVER
        DW PLUS
        DW SWAP
        DW PDO
TYP1:   DW R
        DW CAT
        DW EMIT
        DW LUPE
        DW TYP1
        DW BRCH
        DW $ + 4
        DW DROP
        DW SEMIS
        ;
        ;
        DB $89,"-TRAILIN",$C7 ; -TRAILING
        DW TYPE - 7
TRLG:   DW NEST
        DW DUP
        DW ZERO
        DW PDO
TRL1:   DW OVER
        DW OVER
        DW PLUS
        DW ONE
        DW MINS
        DW CAT
        DW BL
        DW MINS
        DW ZBRCH
        DW $ + 8
        DW LVE
        DW BRCH
        DW $ + 6
        DW ONE        
        DW MINS
        DW LUPE
        DW TRL1
        DW SEMIS
        ;
        ;
        DB $84,$28,$2E,$22,$A9 ; (.")
        DW TRLG - 12
PDQ:    DW NEST
        DW R
        DW CNT
        DW DUP
        DW PLUS1
        DW RG
        DW PLUS
        DW GR
        DW TYPE
        DW SEMIS
        ;
        ;
        DB $86,"EXPEC",$D4 ; EXPECT
        DW PDQ - 7
EXPT:   DW NEST
        DW OVER
        DW PLUS
        DW OVER
        DW PDO
EXPT4:  DW KEY
        DW DUP
        DW LIT
        DW $000E
        DW PORGN
        DW AT
        DW EQL
        DW ZBRCH
        DW EXPT1
        DW DROP
        DW LIT
        DW $0008
        DW OVER
        DW R
        DW EQL
        DW DUP
        DW RG
        DW TWO
        DW MINS
        DW PLUS
        DW GR
        DW MINS
        DW BRCH
        DW EXPT2
EXPT1:  DW DUP
        DW LIT
        DW $000D
        DW EQL
        DW ZBRCH
        DW EXPT3
        DW LVE
        DW DROP
        DW BL
        DW ZERO
        DW BRCH
        DW EXPT5
EXPT3:  DW DUP
EXPT5:  DW R
        DW CEX
        DW ZERO
        DW R
        DW PLUS1
        DW EX
EXPT2:  DW EMIT
        DW LUPE
        DW EXPT4
        DW DROP
        DW SEMIS
        ;
        ;
        DB $85,"QUER",$D9 ; QUERY
        DW EXPT - 9         ; INPUT LINE OF TEXT
QUER:   DW NEST
        DW TIB
        DW AT
        DW LIT
        DW $0050
        DW EXPT
        DW ZERO
        DW FIN
        DW EX
        DW SEMIS
        ;
        ;
        DW $C180           ; X   (IMMEDIATE)
        DW QUER - 8
X:      DW NEST
        DW BLK
        DW AT
        DW ZBRCH
        DW X2
        DW ONE
        DW BLK
        DW PLUSS
        DW ZERO
        DW FIN
        DW EX
        DW BLK
        DW AT
        DW LIT
        DW $0007
        DW FAND
        DW ZEQAL
        DW ZBRCH
        DW X1
        DW EXC
        DW RG
        DW DROP
X1:     DW BRCH
        DW XEND
X2:     DW RG
        DW DROP
XEND:   DW SEMIS
        ;
        ;
        DB $84,"FIL",$CC ; FILL   FILL MEMORY
        DW X - 4
FILL:   DW NEST
        DW SWAP
        DW GR
        DW OVER
        DW CEX
        DW DUP
        DW PLUS1
        DW RG
        DW ONE
        DW MINS
        DW CMOVE
        DW SEMIS
        ;
        ;
        DB $85,"ERAS",$C5 ; ERASE   ZERO MEMORY
        DW FILL - 7
ERS:    DW NEST
        DW ZERO
        DW FILL
        DW SEMIS
        ;
        ;
        DB $86,"BLANK",$D3 ; BLANKS
        DW ERS - 8           ; FILL MEMORY WITH
BLNK:   DW NEST              ; ASCII BLANKS
        DW BL
        DW FILL
        DW SEMIS
        ;
        ;
        DB $84,"HOL",$C4 ; HOLD
        DW BLNK - 9
HOLD:   DW NEST
        DW LIT
        DW $FFFF          ; -1
        DW HLD
        DW PLUSS
        DW HLD
        DW AT
        DW CEX
        DW SEMIS
        ;
        ;
        DB $83,"PA",$C4  ; PAD
        DW HOLD - 7
PAD:    DW NEST
        DW HERE
        DW LIT
        DW $0044
        DW PLUS
        DW SEMIS
        ;
        ;
        DB $84,"WOR",$C4 ; WORD
        DW PAD - 6
WORD:   DW NEST
        DW BLK
        DW AT
        DW ZBRCH
        DW WD1
        DW BLK
        DW AT
        DW BLOCK
        DW BRCH
        DW WD2
WD1:    DW TIB
        DW AT
WD2:    DW FIN
        DW AT
        DW PLUS
        DW SWAP
        DW ENCL
        DW HERE
        DW LIT
        DW $0022
        DW BLNK
        DW FIN
        DW PLUSS
        DW OVER
        DW MINS
        DW GR
        DW R
        DW HERE
        DW CEX
        DW PLUS
        DW HERE
        DW PLUS1
        DW RG
        DW CMOVE
        DW SEMIS
        ;
        ;
        DB $88,"(NUMBER",$A9 ; (NUMBER)
        DW WORD - 7
PNMBR:  DW NEST
        DW PLUS1
        DW DUP
        DW GR
        DW CAT
        DW BASE
        DW AT
        DW DGT
        DW ZBRCH
        DW PNM2
        DW SWAP
        DW BASE
        DW AT
        DW USTAR
        DW DROP
        DW ROT
        DW BASE
        DW AT
        DW USTAR
        DW DPLUS
        DW DPL
        DW AT
        DW PLUS1
        DW ZBRCH
        DW PNM1
        DW ONE
        DW DPL
        DW PLUSS
PNM1:   DW RG
        DW BRCH
        DW PNMBR + 2
PNM2:   DW RG
        DW SEMIS
        ;
        ;
        ;
        DB $86,"NUMBE",$D2 ; NUMBER
        DW PNMBR - 11
NMBR:   DW NEST
        DW ZERO
        DW ZERO
        DW ROT
        DW DUP
        DW PLUS1
        DW CAT
        DW LIT
        DW $002D
        DW EQL
        DW DUP
        DW GR
        DW PLUS
        DW LIT
        DW $FFFF          ; -1
NMB1:   DW DPL
        DW EX
        DW PNMBR
        DW DUP
        DW CAT
        DW BL
        DW MINS
        DW ZBRCH
        DW NMB2
        DW DUP
        DW CAT
        DW LIT
        DW $002E
        DW MINS
        DW ZERO
        DW QERR
        DW ZERO
        DW BRCH
        DW NMB1
NMB2:   DW DROP
        DW RG
        DW ZBRCH
        DW NMB3
        DW DMIN
NMB3:   DW SEMIS
        ;
        ;
        DB $85,"-FIN",$C4 ; -FIND
        DW NMBR - 9
MFIND:  DW NEST
        DW BL
        DW WORD
        DW HERE
        DW CNTX
        DW AT
        DW AT
        DW FIND
        DW DUP
        DW ZEQAL
        DW ZBRCH
        DW MF1
        DW DROP
        DW HERE
        DW LTST
        DW FIND
MF1:    DW SEMIS
        ;
        ;
        DB $87,"(ABORT",$A9 ; (ABORT)
        DW MFIND - 8
PABRT:  DW NEST
        DW ABORT
        DW SEMIS
        ;
        DB $85,"ERRO",$D2 ; ERROR
        DW PABRT - 10
ERROR:  DW NEST
        DW WRNG
        DW AT
        DW ZLESS
        DW ZBRCH
        DW ERR1
        DW PABRT
ERR1:   DW HERE
        DW CNT
        DW TYPE
        DW PDQ
        DB $03,"  ?"
        DW MSG
        DW SP1
        DW FIN
        DW AT
        DW BLK
        DW AT
        DW QUIT
        DW SEMIS
        ;
        DB $83,"MI",$CE  ; MIN
        DW ERROR - 8
MIN:    DW NEST
        DW OVER
        DW OVER
        DW GTR
        DW ZBRCH
        DW MN1
        DW SWAP
MN1:    DW DROP
        DW SEMIS
        ;
        DB $83,"ID",$AE  ; ID.
        DW MIN - 6
ID:     DW NEST
        DW PAD
        DW LIT
        DW $0020
        DW LIT
        DW $005F
        DW FILL
        DW DUP
        DW PFA
        DW LFA
        DW OVER
        DW MINS
        DW PAD
        DW SWAP
        DW CMOVE
        DW PAD
        DW CNT
        DW LIT
        DW $001F
        DW FAND
        DW TYPE
        DW SPC
        DW SEMIS
        ;
        ;
        DB $86,"CREAT",$C5 ; CREATE
        DW ID - 6
CRTE:   DW NEST
        DW FSPAT
        DW HERE
        DW LIT
        DW $00A0
        DW PLUS
        DW LESS
        DW TWO
        DW QERR
        DW MFIND
        DW ZBRCH
        DW CRT1
        DW DROP
        DW NFA
        DW ID
        DW LIT
        DW $0004
        DW MSG
        DW SPC
CRT1:   DW HERE
        DW DUP
        DW CAT
        DW WIDTH
        DW AT
        DW MIN
        DW PLUS1
        DW ALLOT
        DW DUP
        DW LIT
        DW $00A0
        DW TGLE
        DW HERE
        DW ONE
        DW MINS
        DW LIT
        DW $0080
        DW TGLE
        DW LTST
        DW COMMA
        DW CRNT
        DW AT
        DW EX
        DW HERE
        DW PLUS2
        DW COMMA
        DW SEMIS
        ;
        ;
        DW $C1BA          ; :   (IMMEDIATE)
        DW CRTE - 9
COLON:  DW NEST
        DW EXC
        DW DCSP
        DW CRNT
        DW AT
        DW CNTX
        DW EX
        DW CRTE
        DW RBK
        DW LIT
        DW $FFFE          ; -2
        DW DP
        DW PLUSS
        DW CMPL
        DW NEST
        DW SEMIS
        ;
        ;
        DB $85,"!COD",$C5 ; !CODE
        DW COLON - 4
DCODE:  DW NEST
        DW CRTE
        DW SMDG
        DW LTST
        DW PFA
        DW CFA
        DW EX
        DW COMMA
        DW SEMIS
        ;
        ;
        DB $88,"CONSTAN",$D4 ; CONSTANT
        DW DCODE - 8
CNST:   DW NEST
        DW LIT
        DW CONST
        DW DCODE
        DW SEMIS
        ;
        ;
        DB $88,"VARIABL",$C5 ; VARIABLE
        DW CNST - 11
VARB:   DW NEST
        DW LIT
        DW VAR
        DW DCODE
        DW SEMIS
        ;
        ;
        DB $84,"USE",$D2 ; USER
        DW VARB - 11
USR:    DW NEST
        DW LIT
        DW USER
        DW DCODE
        DW SEMIS
        ;
        ;
        DB $87,"<BUILD",$D3 ; <BUILDS
        DW USR - 7
LBLD:   DW NEST
        DW ZERO
        DW CNST
        DW SEMIS
        ;
        ;
        DB $85,"DOES",$BE ; DOES>
        DW LBLD - 10
DOSEG:  DW NEST
        DW RG
        DW LTST
        DW PFA
        DW EX
        DW PCODE
DUZ1:   SEX R2
        GHI RA
        STXD
        GLO RA
        STXD
        LDA RB
        PHI RA
        LDA RB
        PLO RA
        INC R9
        INC R9
        GHI RB
        STR R9
        INC R9
        GLO RB
        STR R9
        DEC R9
        SEP RC
        ;
        ;
        DB $C7,"LITERA",$CC ; LITERAL (IMMEDIATE)
        DW DOSEG - 8
LTL:    DW NEST
        DW STT
        DW AT
        DW ZBRCH
        DW LT1
        DW CMPL
        DW LIT
        DW COMMA
LT1:    DW SEMIS
        ;
        ;
        DB $C8,"DLITERA",$CC ; DLITERAL (IMMEDIATE)
        DW LTL - 10
DLTL:   DW NEST
        DW STT
        DW AT
        DW ZBRCH
        DW DLTL1
        DW SWAP
        DW LTL
        DW LTL
DLTL1:  DW SEMIS
        ;
        ;
        DB $86,"?STAC",$CB ; ?STACK
        DW DLTL - 11
QSTK:   DW NEST
        DW SO
        DW AT
        DW DUP
        DW FSPAT
        DW GTR
        DW ONE
        DW QERR
        DW LIT
        DW $0080  ; kws Size of the allocated area for computation stack
        DW PLUS
        DW FSPAT
        DW LESS
        DW LIT
        DW $0007
        DW QERR
        DW SEMIS
        ;
        ;
        DB $89,"INTERPRE",$D4 ; INTERPRET
        DW QSTK - 9
INPT:   DW NEST
        DW MFIND
        DW ZBRCH
        DW PT1
        DW STT
        DW AT
        DW LESS
        DW ZBRCH
        DW PT2
        DW CFA
        DW COMMA
        DW BRCH
        DW PT3
PT2:    DW CFA
        DW EXE
PT3:    DW QSTK
        DW BRCH
        DW PT4
PT1:    DW HERE
        DW NMBR
        DW DPL
        DW AT
        DW PLUS1
        DW ZBRCH
        DW PT5
        DW DLTL
        DW BRCH
        DW PT6
PT5:    DW DROP
        DW LTL
PT6:    DW QSTK
PT4:    DW BRCH
        DW INPT + 2
        DW SEMIS
        ;
        ;
        DB $8A,"VOCABULAR",$D9 ; VOCABULARY
        DW INPT - 12
VBLY:   DW NEST
        DW LBLD
        DW LIT
        DW $81A0
        DW COMMA
        DW CRNT
        DW AT
        DW CFA
        DW COMMA
        DW HERE
        DW VL
        DW AT
        DW COMMA
        DW VL
        DW EX
        DW DOSEG
VB1:    DW PLUS2
        DW CNTX
        DW EX
        DW SEMIS
        ;
        ;
FRTH:   DB $C5,"FORT",$C8 ; FORTH (IMMEDIATE)
        DW VBLY - 13
        DW DUZ1
        DW VB1
        DW $81A0
        DW TASK - 7        ; DICTION LINK
        DW $0000          ; NOTE THIS MUST BE CHANGED
                            ; TO REFLECT THE LINK TO THE
                            ; LAST DICT WORD IN THE
                            ; FORTH VOCAB
        ;
        ;
        DB $8B,"DEFINITION",$D3 ; DEFINITIONS
        DW FRTH
DFN:    DW NEST
        DW CNTX
        DW AT
        DW CRNT
        DW EX
        DW SEMIS
        ;
        DB $84,"QUI",$D4 ; QUIT
        DW DFN - 14
QUIT:   DW NEST
        DW ZERO
        DW BLK
        DW EX
        DW LB
Q2:     DW RP1
        DW CR
        DW QUER
        DW INPT
        DW STT
        DW AT
        DW ZEQAL
        DW ZBRCH
        DW Q1
        DW PDQ
        DB $04,"  OK"
Q1:     DW BRCH
        DW Q2
        DW SEMIS
        ;
        ;
        DB $85,"ABOR",$D4 ; ABORT
        DW QUIT - 7
ABORT:  DW NEST
        DW SP1
        DW MDCML
        DW CR
        DW PDQ
        DB $1C,"1802 FIG-FORTH R0.4  3/16/81"
	DW DRZER
        DW MTBUF
        DW FIRST
        DW DUP
        DW PREV
        DW EX
        DW USE
        DW EX
        DW FRTH + 8
        DW DFN
        DW QUIT
        DW SEMIS
        ;
        ;
        DW $C1BB          ; ;   (IMMEDIATE)
        DW ABORT - 8
SEMIC:  DW NEST
        DW QCSP
        DW CMPL
        DW SEMIS
        DW SMDG
        DW LB
        DW SEMIS
        ;
        ;
        ;
        DB $C2,$2E,$A2  ; ."   (IMMEDIATE)
        DW SEMIC - 4
DOTQ:   DW NEST
        DW LIT
        DW $0022
        DW STT
        DW AT
        DW ZBRCH
        DW DOTQ1
        DW CMPL
        DW PDQ
        DW WORD
        DW HERE
        DW CAT
        DW PLUS1
        DW ALLOT
        DW BRCH
        DW DOTQ2
DOTQ1:  DW WORD
        DW HERE
        DW CNT
        DW TYPE
DOTQ2:  DW SEMIS
        ;
        ;
        DB $C9,"[COMPILE",$DD ; [COMPILE]
        DW DOTQ - 5             ; (IMMEDIATE)
BCOMP:  DW NEST
        DW MFIND
        DW ZEQAL
        DW ZERO
        DW QERR
        DW DROP
        DW CFA
        DW COMMA
        DW SEMIS
        ;
        ;
        DB $89,"IMMEDIAT",$C5 ; IMMEDIATE
        DW BCOMP - 12
IMMED:  DW NEST
        DW LTST
        DW LIT
        DW $0040
        DW TGLE
        DW SEMIS
        ;
        ;
        DW $C1A8          ; (   (IMMEDIATE)
        DW IMMED - 12
PAREN:  DW NEST
        DW LIT
        DW $0029
        DW WORD
        DW SEMIS
        ;
        ;
        DW $81B3          ; 3
        DW PAREN - 4
THREE:  DW CONST
        DW $0003
        ;
        ;
        DW $C1A7          ; '   (TICK)   (IMMEDIATE)
        DW THREE - 4
TICK:   DW NEST
        DW MFIND
        DW ZEQAL
        DW ZERO
        DW QERR
        DW DROP
        DW LTL
        DW SEMIS
        ;
        ;
        DB $86,"FORGE",$D4 ; FORGET
        DW TICK - 4
FORG:   DW NEST
        DW CRNT
        DW AT
        DW CNTX
        DW AT
        DW MINS
        DW LIT
        DW $0018
        DW QERR
        DW TICK
        DW DUP
        DW FNCE
        DW AT
        DW LESS
        DW LIT
        DW $0015
        DW QERR
        DW DUP
        DW NFA
        DW DP
        DW EX
        DW LFA
        DW AT
        DW CNTX
        DW AT
        DW EX
        DW SEMIS
        ;
        ;
        DB $82,$2B,$AD  ; +-
        DW FORG - 9
PM:     DW NEST
        DW ZLESS
        DW ZBRCH
        DW PM1
        DW MINUS
PM1:    DW SEMIS
        ;
        DB $83,$44,$2B,$AD ; D+-
        DW PM - 5
DPM:    DW NEST
        DW ZLESS
        DW ZBRCH
        DW DPM1
        DW DMIN
DPM1:   DW SEMIS
        ;
        DB $83,$41,$42,$D3 ; ABS
        DW DPM - 6
ABS:    DW NEST
        DW DUP
        DW PM
        DW SEMIS
        ;
        DB $84,"DAB",$D3 ; DABS
        DW ABS - 6
DABS:   DW NEST
        DW DUP
        DW DPM
        DW SEMIS
        ;
        DB $83,$4D,$41,$D8 ; MAX
        DW DABS - 7
MAX:    DW NEST
        DW OVER
        DW OVER
        DW LESS
        DW ZBRCH
        DW MAX1
        DW SWAP
MAX1:   DW DROP
        DW SEMIS
        ;
        DB $82,$4D,$AA  ; M*
        DW MAX - 6
MSTAR:  DW NEST
        DW OVER
        DW OVER
        DW FXOR
        DW GR
        DW ABS
        DW SWAP
        DW ABS
        DW USTAR
        DW RG
        DW DPM
        DW SEMIS
        ;
        DB $82,$4D,$AF  ; M/
        DW MSTAR - 5
MSLAS:  DW NEST
        DW OVER
        DW GR
        DW GR
        DW DABS
        DW R
        DW ABS
        DW USLSH
        DW RG
        DW R
        DW FXOR
        DW PM
        DW SWAP
        DW RG
        DW PM
        DW SWAP
        DW SEMIS
        ;
        DW $81AA          ; *
        DW MSLAS - 5
STAR:   DW NEST
        DW MSTAR
        DW DROP
        DW SEMIS
        ;
        DB $84,$2F,$4D,$4F,$C4 ; /MOD
        DW STAR - 4
SLMOD:  DW NEST
        DW GR
        DW STOD
        DW RG
        DW MSLAS
        DW SEMIS
        ;
        DW $81AF          ; /
        DW SLMOD - 7
SLASH:  DW NEST
        DW SLMOD
        DW SWAP
        DW DROP
        DW SEMIS
        ;
        DB $83,$4D,$4F,$C4 ; MOD
        DW SLASH - 4
MODD:   DW NEST
        DW SLMOD
        DW DROP
        DW SEMIS
        ;
        DB $85,"*/MO",$C4 ; */MOD
        DW MODD - 6
SSMOD:  DW NEST
        DW GR
        DW MSTAR
        DW RG
        DW MSLAS
        DW SEMIS
        ;
        DB $82,$2A,$AF ; */
        DW SSMOD - 8
SSLA:   DW NEST
        DW SSMOD
        DW SWAP
        DW DROP
        DW SEMIS
        ;
        DB $85,"M/MO",$C4 ; M/MOD
        DW SSLA - 5
MSMOD:  DW NEST
        DW GR
        DW ZERO
        DW R
        DW USLSH
        DW RG
        DW SWAP
        DW GR
        DW USLSH
        DW RG
        DW SEMIS
        ;
        ;
        DB $83,"MO",$CE  ; MON
        DW MSMOD - 8       ; RETURN TO MONITOR
MON:    DW $ + 2
        ; Return to the MCSMP Monitor via SEP R1
        ; - We could instead jump back into the monitor with a LBR,
        ;   which would free up R1.  But having R1 intact is handy
        ;   for setting D1 breakpoints under MCSMP.  And R1 isn't
        ;   used anyway.
        SEP R1
        ;
        ;
        DB $83,"BY",$C5  ; BYE
        DW MON - 6
BYE:    DW NEST
        DW FLUSH
        DW MON
        ;
        ;
        DB $84,"BAC",$CB ; BACK
        DW BYE - 6
BACK:   DW NEST
        DW COMMA
        DW SEMIS
        ;
        DB $C5,"BEGI",$CE ; BEGIN
        DW BACK - 7
BEGIN:  DW NEST
        DW QCMP
        DW HERE
        DW ONE
        DW SEMIS
        ;
        DB $C5,"ENDI",$C6 ; ENDIF
        DW BEGIN - 8
ENDIFF: DW NEST
        DW QCMP
        DW TWO
        DW QPR
        DW HERE
        DW SWAP
        DW EX
        DW SEMIS
        ;
        DB $C4,"THE",$CE ; THEN
        DW ENDIFF - 8
THEN:   DW NEST
        DW ENDIFF
        DW SEMIS
        ;
        DB $C2,$44,$CF  ; DO
        DW THEN - 7
DO:     DW NEST
        DW CMPL
        DW PDO
        DW HERE
        DW THREE
        DW SEMIS
        ;
        DB $C4,$4C,$4F,$4F,$D0 ; LOOP
        DW DO - 5
LOOP:   DW NEST
        DW THREE
        DW QPR
        DW CMPL
        DW LUPE
        DW BACK
        DW SEMIS
        ;
        DB $C5,"+LOO",$D0 ; +LOOP
        DW LOOP - 7
PLOOP:  DW NEST
        DW THREE
        DW QPR
        DW CMPL
        DW PLUPE
        DW BACK
        DW SEMIS
        ;
        DB $C5,"UNTI",$CC ; UNTIL
        DW PLOOP - 8
UNTIL:  DW NEST
        DW ONE
        DW QPR
        DW CMPL
        DW ZBRCH
        DW BACK
        DW SEMIS
        ;
        DB $C3,$45,$4E,$C4 ; END
        DW UNTIL - 8
ENDD:   DW NEST
        DW UNTIL
        DW SEMIS
        ;
        DB $C5,"AGAI",$CE ; AGAIN
        DW ENDD - 6
AGAIN:  DW NEST
        DW ONE
        DW QPR
        DW CMPL
        DW BRCH
        DW BACK
        DW SEMIS
        ;
        DB $C6,"REPEA",$D4 ; REPEAT
        DW AGAIN - 8
REPEA:  DW NEST
        DW GR
        DW GR
        DW AGAIN
        DW RG
        DW RG
        DW TWO
        DW MINS
        DW ENDIFF
        DW SEMIS
        ;
        DB $C2,$49,$C6 ; IF
        DW REPEA - 9
IFF:    DW NEST
        DW CMPL
        DW ZBRCH
        DW HERE
        DW ZERO
        DW COMMA
        DW TWO
        DW SEMIS
        ;
        DB $C4,"ELS",$C5 ; ELSE
        DW IFF - 5
ELSEE:  DW NEST
        DW TWO
        DW QPR
        DW CMPL
        DW BRCH
        DW HERE
        DW ZERO
        DW COMMA
        DW SWAP
        DW TWO
        DW ENDIFF
        DW TWO
        DW SEMIS
        ;
        DB $C5,"WHIL",$C5 ; WHILE
        DW ELSEE - 7
WHILE:  DW NEST
        DW IFF
        DW PLUS2
        DW SEMIS
        ;
        DB $86,"SPACE",$D3 ; SPACES
        DW WHILE - 8
SPACS:  DW NEST
        DW ZERO
        DW MAX
        DW MDUP
        DW ZBRCH
        DW SPAX1
        DW ZERO
        DW PDO
SPAX2:  DW SPC
        DW LUPE
        DW SPAX2
SPAX1:  DW SEMIS
        ;
        DB $82,$3C,$A3  ; <#
        DW SPACS - 9
BDIGS:  DW NEST
        DW PAD
        DW HLD
        DW EX
        DW SEMIS
        ;
        DB $82,$23,$BE  ; #>
        DW BDIGS - 5
EDIGS:  DW NEST
        DW DROP
        DW DROP
        DW HLD
        DW AT
        DW PAD
        DW OVER
        DW MINS
        DW SEMIS
        ;
        DB $84,"SIG",$CE ; SIGN
        DW EDIGS - 5
SIGN:   DW NEST
        DW ROT
        DW ZLESS
        DW ZBRCH
        DW SIGN1
        DW LIT
        DW $002D
        DW HOLD
SIGN1:  DW SEMIS
        ;
        DW $81A3          ; #
        DW SIGN - 7
DIG:    DW NEST
        DW BASE
        DW AT
        DW MSMOD
        DW ROT
        DW LIT
        DW $0009
        DW OVER
        DW LESS
        DW ZBRCH
        DW DIG1
        DW LIT
        DW $0007
        DW PLUS
DIG1:   DW LIT
        DW $0030
        DW PLUS
        DW HOLD
        DW SEMIS
        ;
        DB $82,$23,$D3  ; #S
        DW DIG - 4
DIGS:   DW NEST
DIGS1:  DW DIG
        DW OVER
        DW OVER
        DW FFOR
        DW ZEQAL
        DW ZBRCH
        DW DIGS1
        DW SEMIS
        ;
        DB $83,$44,$2E,$D2 ; D.R
        DW DIGS - 5
DDOTR:  DW NEST
        DW GR
        DW SWAP
        DW OVER
        DW DABS
        DW BDIGS
        DW DIGS
        DW SIGN
        DW EDIGS
        DW RG
        DW OVER
        DW MINS
        DW SPACS
        DW TYPE
        DW SEMIS
        ;
        DB $82,$2E,$D2  ; .R
        DW DDOTR - 6
DOTR:   DW NEST
        DW GR
        DW STOD
        DW RG
        DW DDOTR
        DW SEMIS
        ;
        DB $82,$44,$AE  ; D.
        DW DOTR - 5
DDOT:   DW NEST
        DW ZERO
        DW DDOTR
        DW SPC
        DW SEMIS
        ;
        DW $81AE          ; .   (DOT)
        DW DDOT - 5
DOT:    DW NEST
        DW STOD
        DW DDOT
        DW SEMIS
        ;
        DW $81BF          ; ?
        DW DOT - 4
QUES:   DW NEST
        DW AT
        DW DOT
        DW SEMIS
        ;
        DB $82,$55,$AE  ; U.
        DW QUES - 4
UDOT:   DW NEST
        DW ZERO
        DW DDOT
        DW SEMIS
        ;
        DB $85,"VLIS",$D4 ; VLIST
        DW UDOT - 5
VLIST:  DW NEST
        DW CR
        DW LIT
        DW $0080
        DW FOUT
        DW EX
        DW CNTX
        DW AT
        DW AT
VLIS1:  DW FOUT
        DW AT
        DW CL
        DW GTR
        DW ZBRCH
        DW VLIS2
        DW CR
        DW ZERO
        DW FOUT
        DW EX
VLIS2:  DW DUP
        DW ID
        DW SPC
        DW SPC
        DW PFA
        DW LFA
        DW AT
        DW DUP
        DW ZEQAL
        DW QTERM
        DW FFOR
        DW ZBRCH
        DW VLIS1
        DW DROP
        DW SEMIS
        ;
        ;
        DB $87,"MESSAG",$C5 ; MESSAGE
        DW VLIST - 8
MSG:    DW NEST
        DW WRNG
        DW AT
        DW ZBRCH
        DW MESS1
        DW MDUP
        DW ZBRCH
        DW MESS2
        DW LIT
        DW $0004
        DW OFST
        DW AT
        DW BSCR
        DW SLASH
        DW MINS
        DW DLINE
        DW SPC
MESS2:  DW BRCH
        DW MESS3
MESS1:  DW PDQ
        DB $07," MSG # "
        DW DOT
MESS3:  DW SEMIS
        ;
        ;
        DW $81C9          ; I
        DW MSG - 10
I:      DW $ + 2
        INC R2
        INC R9
        INC R9
        INC R9
        LDA R2
        STR R9
        DEC R9
        LDN R2
        STR R9
        DEC R2
        DEC R2
        SEP RC
        ;
        DB $84,"WAR",$CD ; WARM
        DW I - 4
WRM:    DW $ + 2
        LBR WARM
        ;
        ;
        DB $84,"COL",$C4 ; COLD
        DW WRM - 7
CLD:    DW $ + 2
        LBR COLD
        ;
        ;
        DB $84,"S->",$C4 ; S->D
        DW CLD - 7
STOD:   DW $ + 2
        LDA R9
        SHL
        BDF SNEG
        LDI $00
        BR SSKP
SNEG:   LDI $FF
SSKP:   INC R9
        STR R9
        INC R9
        STR R9
        DEC R9
        SEP RC
        ;
        DB $86,"(LINE",$A9 ; (LINE)
        DW STOD - 7
PLINE:  DW NEST
        DW GR
        DW LIT
        DW $0040
        DW BBUF
        DW SSMOD
        DW RG
        DW BSCR
        DW STAR
        DW PLUS
        DW BLOCK
        DW PLUS
        DW LIT
        DW $0040
        DW SEMIS
        ;
        DB $85,".LIN",$C5 ; .LINE
        DW PLINE - 9
DLINE:  DW NEST
        DW PLINE
        DW TRLG
        DW TYPE
        DW SEMIS
        ;
        DB $83,"US",$C5  ; USE (ADDR OF
        DW DLINE - 8       ; NEXT BUFFER TO USE)
USE:    DW VAR
        DW FIRSTB
        ;
        DB $84,"PRE",$D6 ; PREV   (ADDR OF
        DW USE - 6         ; PREVIOUSLY USED BUFFER)
PREV:   DW VAR
        DW FIRSTB
        ;
        DB $84,"+BU",$C6 ; +BUF
        DW PREV - 7        ; ADVANCE
PBUF:   DW NEST            ;    BUFFER
        DW BBUF
        DW LIT
        DW $0004
        DW PLUS
        DW PLUS
        DW DUP
        DW LIMIT
        DW EQL
        DW ZBRCH
        DW PBUF1
        DW DROP
        DW FIRST
PBUF1:  DW DUP
        DW PREV
        DW AT
        DW MINS
        DW SEMIS
        ;
        DB $86,"UPDAT",$C5 ; UPDATE
        DW PBUF - 7
UPDAT:  DW NEST
        DW PREV
        DW AT
        DW AT
        DW LIT
        DW $8000
        DW FFOR
        DW PREV
        DW AT
        DW EX
        DW SEMIS
        ;
        DB $8D,"EMPTY-BUFFER",$D3 ; EMPTY-BUFFER
        DW UPDAT - 9
MTBUF:  DW NEST
        DW FIRST
        DW LIMIT
        DW OVER
        DW MINS
        DW ERS
        DW SEMIS
        ;
        ;
        DB $86,"BUFFE",$D2 ; BUFFER
        DW MTBUF - 16
BUFFE:  DW NEST
        DW USE
        DW AT
        DW DUP
        DW GR
BUFF1:  DW PBUF
        DW ZBRCH
        DW BUFF1
        DW USE
        DW EX
        DW R
        DW AT
        DW ZLESS
        DW ZBRCH
        DW BUFF2
        DW R
        DW PLUS2
        DW R
        DW AT
        DW LIT
        DW $7FFF
        DW FAND
        DW ZERO
        DW RSLW
BUFF2:  DW R
        DW EX
        DW R
        DW PREV
        DW EX
        DW RG
        DW PLUS2
        DW SEMIS
        ;
        DB $85,"BLOC",$CB ; BLOCK
        DW BUFFE - 9
BLOCK:  DW NEST
        DW OFST
        DW AT
        DW PLUS
        DW GR
        DW PREV
        DW AT
        DW DUP
        DW AT
        DW R
        DW MINS
        DW DUP
        DW PLUS
        DW ZBRCH
        DW BLOC1
BLOC2:  DW PBUF
        DW ZEQAL
        DW ZBRCH
        DW BLOC3
        DW DROP
        DW R
        DW BUFFE
        DW DUP
        DW R
        DW ONE
        DW RSLW
        DW TWO
        DW MINS
BLOC3:  DW DUP
        DW AT
        DW R
        DW MINS
        DW DUP
        DW PLUS
        DW ZEQAL
        DW ZBRCH
        DW BLOC2
        DW DUP
        DW PREV
        DW EX
BLOC1:  DW RG
        DW DROP
        DW PLUS2
        DW SEMIS
        ;
        DB $83,$52,$2F,$D7 ; R/W
        DW BLOCK - 8
RSLW:   DW NEST
        DW SWAP
        DW LIT
        DW $00FA
        DW SLMOD
        DW DUP
        DW LIT
        DW $0003
        DW GTR
        DW LIT
        DW $0005
        DW QERR
        DW SWAP
        DW LIT
        DW $0008
        DW STAR
        DW LIT
        DW $0001
        DW PLUS
        DW LIT
        DW $001A
        DW SLMOD
        DW DV
        DW CEX
        DW ONE
        DW MINS
        DW SWAP
        DW LIT
        DW $0040
        DW STAR
        DW PLUS
        DW DV
        DW PLUS1
        DW CEX
        DW ZERO
        DW DV
        DW PLUS2
        DW CEX
        DW DV
        DW BBUF
        DW ROT
        DW ZBRCH
        DW RWELSE
        DW BLKRD
        DW BRCH
        DW RWEND
RWELSE: DW BLKWT
RWEND:  DW SEMIS
        DB $0A,"BLOCK-REA",$C4 ; BLOCKREAD
        DW RSLW - 6
BLKRD:  DW $ + 2
        LDI $83
        PHI R4
        PHI R5
        LDI $64
        PLO R4
        LDI $74
        PLO R5
        ;
        SEX R2
        GHI RC
        STXD
        GLO RC
        STXD
        LDA R9
        PHI R7
        LDN R9
        PLO R7
        DEC R9
        DEC R9
        LDN R9
        PLO RC
        DEC R9
        LDN R9
        PHI RC
        INC RC
        INC RC
        DEC R9
        LDN R9
        PLO R8
        DEC R9
        LDN R9
        PHI R8
        DEC R9
        DEC R9
BLKRD2: SEP R4
        DW $8502
        GHI RF
        STR R8
        INC R8
        DEC R7
        GHI R7
        LBNZ BLKRD2
        GLO R7
        LBNZ BLKRD2
        ;
        SEX R2
        IRX
        LDXA
        PLO RC
        LDX
        PHI RC
        SEP RC
        ;
        DB $0B,"BLOCK-WRIT",$C5 ; BLOCK-WRITE
        DW BLKRD - 13
BLKWT:  DW $ + 2
        LDI $83
        PHI R4
        PHI R5
        LDI $64
        PLO R4
        LDI $74
        PLO R5
        ;
        SEX R2
        GHI RC
        STXD
        GLO RC
        STXD
        LDA R9
        PHI R7
        LDN R9
        PLO R7
        DEC R9
        DEC R9
        LDN R9
        PLO RC
        DEC R9
        LDN R9
        PHI RC
        INC RC
        INC RC
        DEC R9
        LDN R9
        PLO R8
        DEC R9
        LDN R9
        PHI R8
        DEC R9
        DEC R9
BLKWT2: LDA R8
        PHI RF
        SEP R4
        DW $8500
        DEC R7
        GHI R7
        LBNZ BLKWT2
        GLO R7
        LBNZ BLKWT2
        ;
        SEX R2
        IRX
        LDXA
        PLO RC
        LDX
        PHI RC
        SEP RC
        ;
        DB $84,"LOA",$C4 ; LOAD
        DW BLKWT - 14
LOAD:   DW NEST
        DW BLK
        DW AT
        DW GR
        DW FIN
        DW AT
        DW GR
        DW ZERO
        DW FIN
        DW EX
        DW BSCR
        DW STAR
        DW BLK
        DW EX
        DW INPT
        DW RG
        DW FIN
        DW EX
        DW RG
        DW BLK
        DW EX
        DW SEMIS
        ;
        DB $C3,"--",$BE ; -->
        DW LOAD - 7
ARROW:  DW NEST      
        DW QLDG
        DW ZERO
        DW FIN
        DW EX
        DW BSCR
        DW BLK
        DW AT
        DW OVER
        DW MODD
        DW MINS
        DW BLK
        DW PLUSS
        DW SEMIS
        ;
        ;
        DB $83,$44,$52,$B0 ; DR0
        DW ARROW - 6
DRZER:  DW NEST
        DW ZERO
        DW OFST
        DW EX
        DW SEMIS
        ;
        ;
        DB $83,$44,$52,$B1 ; DR1
        DW DRZER - 6
DRONE:  DW NEST
        DW BSCR
        DW LIT             ; 250 SCREENS/DISK
        DW $00FA
        DW STAR
        DW OFST
        DW EX
        DW SEMIS
        ;
        ;
        DB $84,"LIS",$D4 ; LIST
        DW DRONE - 6
LIST:   DW NEST
        DW MDCML
        DW CR
        DW DUP
        DW FSCR
        DW EX
        DW PDQ
        DB $06,"SCR # "
        DW DOT
        DW LIT
        DW $0010
        DW ZERO
        DW PDO
LIST1:  DW CR
        DW I
        DW LIT
        DW $0003
        DW DOTR
        DW SPC
        DW I
        DW FSCR
        DW AT
        DW DLINE
        DW QTERM
        DW ZBRCH
        DW LIST2
        DW LVE
LIST2:  DW LUPE
        DW LIST1
        DW CR
        DW SEMIS
        ;
        ;
        DB $85,"INDE",$D8 ; INDEX
        DW LIST - 7
INDEX:  DW NEST
        DW CR
        DW PLUS1
        DW SWAP
        DW PDO
INDE1:  DW CR      
        DW I
        DW LIT
        DW $0003
        DW DOTR
        DW SPC
        DW ZERO
        DW I
        DW DLINE
        DW QTERM
        DW ZBRCH
        DW INDE2
        DW LVE
INDE2:  DW LUPE
        DW INDE1
        DW SEMIS
        ;
        DB $85,"TRIA",$C4 ; TRIAD
        DW INDEX - 8
TRIAD:  DW NEST
        DW CR
        DW LIT
        DW $0003
        DW SLASH
        DW LIT
        DW $0003
        DW STAR
        DW LIT
        DW $0003
        DW OVER
        DW PLUS
        DW SWAP
        DW PDO
TRIA1:  DW CR
        DW I
        DW LIST
        DW QTERM
        DW ZBRCH
        DW TRIA2
        DW LVE
TRIA2:  DW LUPE
        DW TRIA1
        DW CR
        DW LIT
        DW $000F
        DW MSG
        DW CR
        DW SEMIS
        ;
        ;
        DB $85,"FLUS",$C8 ; FLUSH
        DW TRIAD - 8
FLUSH:  DW NEST
        DW LIMIT
        DW FIRST
        DW MINS
        DW BBUF
        DW LIT
        DW $0004
        DW PLUS
        DW SLASH
        DW ZERO
        DW PDO
FL1:    DW LIT
        DW $7FFF
        DW BUFFE
        DW DROP
        DW LUPE
        DW FL1
        DW SEMIS
        ;
        ;
        DB $84,"TAS",$CB ; TASK
        DW FLUSH - 8
TASK:   DW NEST              
        DW SEMIS
        ;
        ;
        PAGE
        ;
        ;        
COLD:   LDI HIGH (START + 12) ; >> 8
        PHI R7
        LDI LOW (START + 12)
        PLO R7
        LDI HIGH (FRTH + 14) ; >> 8
        PHI R8
        LDI LOW (FRTH + 14)
        PLO R8
        LDA R7
        STR R8
        INC R8
        LDA R7
        STR R8
        LDI $16
        BR PUTF
WARM:   LDI $10
PUTF:   PLO RF
        LDI HIGH (START + $10) ; >> 8
        PHI R7
        LDI LOW (START + $10)
        PLO R7
        LDA R7
        PHI RD
        PHI R8
        LDN R7
        PLO RD
        PLO R8
        LDI LOW (START + 12)
        PLO R7
WRMLP:  LDA R7
        STR R8
        INC R8
        DEC RF
        GLO RF
        BNZ WRMLP
        LDI HIGH NEXT ;>> 8
        PHI RC
        LDI LOW NEXT
        PLO RC
        LDI LOW (ABORT + 2)
        PLO RA
        LDI HIGH (ABORT + 2) ;>> 8
        PHI RA
        ; Clear stack areas for debugging
        LOAD R7, START + $14
        LDA R7
        PHI R9
        LDN R7
        PLO R9  ; R9 has end address
        LOAD R7, START + $12
        LDA R7
        PHI R8
        LDN R7
        PLO R8  ; R8 has start address
        SEX R7
        GLO R9  ; Compute count (R9 - start address)
        SM
        PLO R9
        DEC R7
        GHI R9
        SMB
        PHI R9
        INC R9  ; R9 has count
ZEROLP: LDI $0
        STR R8
        INC R8
        DEC R9
        GHI R9
        BNZ ZEROLP
        GLO R9
        BNZ ZEROLP
        LBR (RP1 + 2)
        ;
LEND:   NOP                 ; INITIAL FENCE IS HERE
        ;
        ; TO EXTEND THIS PORTION TO INCLUDE
        ; NEW WORDS, FIRST USE
        ;    HERE.  TO FIND END OF YOUR NEW VERSION
        ; THEN USE THE FOLLOWING:
        ;
        ;    LATEST 12 +ORIGIN !
        ;    HERE  28 +ORIGIN !
        ;    HERE  30 +ORIGIN !
        ;    HERE FENCE !
        ;
        ; THEN USE   BYE TO GET BACK TO YOUR MONITOR
        ; THEN USE YOUR MONITOR ROUTINES TO SAVE MEMORY
        ; FROM 0000 TO END ADDRESS
        ;
        ; THIS PROCEDURE WILL ALLOW YOU TO CONTINUE
        ; BUILDING ON YOUR FORTH VOCABULARY WITHOUT THE
        ; DISC INTERFACE
        ;
        ;
        ;
        ;
        ;
        END
        