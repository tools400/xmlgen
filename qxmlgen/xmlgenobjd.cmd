      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - Retr Obj Desc           */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENOBJD - RETRIEVE OBJECT DESCRIPTION ATTRIBUTES                       */
/*                                                                           */
/* COPYRIGHT (C) 2011  THOMAS RADDATZ  <THOMAS.RADDATZ@TOOLS400.DE>          */
/*                                                                           */
/* This program is free software, you can redistribute it and/or modify it   */
/* under the terms of the GNU General Public License as published by         */
/* the Free Software Foundation.  See GNU General Public License for detail. */
/* ------------------------------------------------------------------------- */
/* >>PRE-COMPILER<<                                                          */
/*   >>CRTCMD<< CRTCMD       CMD(&LI/&OB) +                                  */
/*                           SRCFILE(&SL/&SF) +                              */
/*                           SRCMBR(&SM);                                    */
/*   >>IMPORTANT<<                                                           */
/*     >>PARM<< PGM(*LIBL/&OB);                                              */
/*     >>PARM<< ALLOW(*IPGM *BPGM);                                          */
/*   >>END-IMPORTANT<<                                                       */
/*   >>EXECUTE<<                                                             */
/* >>END-PRE-COMPILER<<                                                      */
/* ------------------------------------------------------------------------- */

             CMD        PROMPT('Script - Retrieve object desc.')

             PARM       KWD(XOBJ) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Object name')

             PARM       KWD(XLIB) TYPE(*NAME) LEN(10) MIN(1) +
                          SPCVAL(*LIBL) +
                          PROMPT('Library name')

             PARM       KWD(XOBJTYPE) TYPE(*CHAR) LEN(10) MIN(1) +
                          RSTD(*YES) +
                          VALUES(*PGM *SRVPGM) +
                          PROMPT('Object type')

             PARM       KWD(XRTNLIB) TYPE(*CHAR) LEN(11) MIN(0) +
                          RTNVAL(*YES) +
                          PROMPT('CL var for RTNLIB')

             PARM       KWD(XCND) TYPE(*CHAR) LEN(10) MIN(0) MAX(5) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('Condition')

