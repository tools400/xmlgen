      /*%METADATA                                                     */
      /* %TEXT Cmd for script member - Version                        */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENVRS  - Retrieve version from source member (COPYRIGHT).             */
/*                                                                           */
/* COPYRIGHT (C) 2018  Thomas Raddatz  <thomas.raddatz@tools400.de>          */
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
/*     >>PARM<< ALLOW(*BPGM *IPGM *BREXX *IREXX *BMOD *IMOD);                */
/*   >>END-IMPORTANT<<                                                       */
/*   >>EXECUTE<<                                                             */
/* >>END-PRE-COMPILER<<                                                      */
/* ------------------------------------------------------------------------- */

             CMD        PROMPT('Script - Retrieve Version')


             PARM       KWD(XSRCFILE) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Source file name')

             PARM       KWD(XSRCLIB) TYPE(*NAME) LEN(10) MIN(1) +
                          SPCVAL(*LIBL) +
                          PROMPT('Source file library name')

             PARM       KWD(XSRCMBR) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Source member')

             PARM       KWD(XRTNVRS) TYPE(*CHAR) LEN(15) MIN(0) +
                          RTNVAL(*YES) +
                          PROMPT('CL var for RTNVRS')

