      /*%METADATA                                                     */
      /* %TEXT Cmd prompt for script member - Include install         */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------- */
/* XMLGENINC - PROMPT IN SCRIPT MEMBER TO INCLUDE GENERATED                  */
/*             INSTALL PROGRAM / DTD / INSTALLATION INSTRUCTIONS             */
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

             CMD        PROMPT('Script - Gen install pgm code?')

             PARM       KWD(XINCLUDE) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          VALUES(*YES *NO) MIN(1) PROMPT('Install +
                          pgm/DTD/Instructions')

