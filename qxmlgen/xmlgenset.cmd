      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - Set variable            */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENSET  - SET VARIABLE                                                 */
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
/*   >>END-IMPORTANT<<                                                       */
/*   >>EXECUTE<<                                                             */
/* >>END-PRE-COMPILER<<                                                      */
/* ------------------------------------------------------------------------- */

             CMD        PROMPT('Script - Set Variable')

             PARM       KWD(XVAR) TYPE(*VARNAME) LEN(11) MIN(1) +
                          PROMPT('CL variable name')

             PARM       KWD(XVALUE) TYPE(*CHAR) LEN(64) MIN(1) +
                          CASE(*MIXED) +
                          PROMPT('New value')

             PARM       KWD(XCND) TYPE(*CHAR) LEN(10) MIN(0) MAX(5) +
                          DFT(*NONE) +
                          SPCVAL(*NONE) +
                          PROMPT('Condition')

