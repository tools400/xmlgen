      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - QCMDEXC                 */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENCMD - PROMPT IN SCRIPT MEMBER FOR COMMANDS TO EXECUTE               */
/*                                                                           */
/* COPYRIGHT (C) 2001  MARTIN ROWE  <MARTIN@DBG400.NET>                      */
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
/*   >>END-IMPORTANT<<                                                       */
/*   >>EXECUTE<<                                                             */
/* >>END-PRE-COMPILER<<                                                      */
/* ------------------------------------------------------------------------- */

             CMD        PROMPT('Script - Command Prompt')

             PARM       KWD(XCMD) TYPE(*CMDSTR) LEN(2000) MIN(1) +
                          PROMPT('Command to execute')

             PARM       KWD(XCND) TYPE(*CHAR) LEN(10) MIN(0) MAX(5) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('Condition')

             PARM       KWD(XRLS) TYPE(ELEM1) MIN(0) MAX(1) +
                          SNGVAL((*CURRENT CU))             +
                          DFT(*CURRENT)                     +
                          PROMPT('Execute on Release')

             PARM       KWD(XDLTSPLF) TYPE(*NAME) LEN(10) MIN(0) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('Delete spooled file on success')

ELEM1:       ELEM       TYPE(*CHAR)                                 +
                          LEN(2)                                    +
                          DFT(*EQ)                                  +
                          SPCVAL((*LT LT)                           +
                                 (*EQ EQ)                           +
                                 (*GT GT)                           +
                                 (*LE LE)                           +
                                 (*GE GE))                          +
                          RSTD(*YES)                                +
                          PROMPT('Relational Operator')
             ELEM       TYPE(*CHAR)                                 +
                          LEN(6)                                    +
                          DFT(*CURRENT)                             +
                          SPCVAL((*CURRENT V0R0M0))                 +
                          PROMPT('Release (VxRyMz)')

