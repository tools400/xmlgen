      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - SQL-Cmd                 */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENSQL - PROMPT IN SCRIPT MEMBER FOR COMMANDS TO EXECUTE               */
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

             CMD        PROMPT('Script - SQL-Command Prompt')

             PARM       KWD(XSQL) TYPE(*CHAR) LEN(2000) MIN(1) +
                          EXPR(*YES) +
                          PROMPT('SQL-Command to execute')

             PARM       KWD(XCND) TYPE(*CHAR) LEN(10) MIN(0) MAX(5) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('Condition')


