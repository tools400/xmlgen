      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - Condition               */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENCND - PROMPT IN SCRIPT MEMBER FOR CONDITION                         */
/*                                                                           */
/* COPYRIGHT (C) 2001  THOMAS RADDATZ  <THOMAS.RADDATZ@TOOLS400.DE>          */
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

             CMD        PROMPT('Script - Condition Prompt')

             PARM       KWD(XMSG) TYPE(*CHAR) LEN(52) +
                          MIN(1) +
                          EXPR(*YES) +
                          PROMPT('Message Text')

             PARM       KWD(XVALUES) TYPE(*CHAR) LEN(10) +
                          MIN(0) +
                          MAX(10) +
                          PROMPT('Values')

             PARM       KWD(XVAR) TYPE(*VARNAME) LEN(11) MIN(0) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('CL variable name')                                  /* RADD */

