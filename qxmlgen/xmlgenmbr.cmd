      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - Source member           */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENMBR - PROMPT IN SCRIPT MEMBER FOR SOURCE MEMBER INFORMATION         */
/*             TO LOAD MEMBERS INTO OUTPUT FILE.                             */
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

             CMD        PROMPT('Script - Source member info')

             PARM       KWD(XMBR) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Member name')

             PARM       KWD(XMBRATR) TYPE(*NAME) LEN(10) MIN(1) +
                          CHOICE('RPGLE CLP DSPF CMD etc') +
                          PROMPT('Source member attribute')

             PARM       KWD(XFROMSRCF) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Copy from source file')

             PARM       KWD(XFROMSRCL) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Copy from source lib')

             PARM       KWD(XTOSRCF) TYPE(*NAME) LEN(10) MIN(1) +
                          CHOICE('QRPGLESRC QCLSRC QDDSSRC etc') +
                          PROMPT('Target source file')

             PARM       KWD(XOBJTYPE) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          VALUES(*CMD *FILE *MENU *MODULE *PGM +
                          *PNLGRP *QMQRY *SQLPKG *SRVPGM *TBL) +
                          MIN(1) MAX(1) EXPR(*YES) PROMPT('Object +
                          type')

             PARM       KWD(XGENCRT) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          VALUES(*YES *NO) MIN(1) PROMPT('Generate +
                          compile code for mbr')

             PARM       KWD(XPARAM) TYPE(*CHAR) LEN(200) RSTD(*NO) +
                          MIN(0) DFT(*BLANK) PROMPT('Optional +
                          command parameter')

             PARM       KWD(XCND) TYPE(*CHAR) LEN(10) MIN(0) MAX(5) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('Condition')

