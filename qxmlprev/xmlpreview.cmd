      /*%METADATA                                                     */
      /* %TEXT Preview uploaded xml member before install     jcr     */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------ */
/* XMLPREVIEW - PREVIEW UPLOADED XML BEFORE INSTALL - JCR                   */
/* Copyright (C) 2001       Craig Rutledge    <craig_rutledge@mohawkind.com> */
/*                                                                          */
/* This program is free software, you can redistribute it and/or modify it  */
/* under the terms of the GNU General Public License as published by        */
/* the Free Software Foundation.  See GNU General Public License for detail. */
/* ------------------------------------------------------------------------ */
/* Related Objects:                                                         */
/* XMLPREVIEC   *PGM    CLP      command processing program                 */
/* XMLPREVIEV   *PGM    CLP      validity checker                           */
/* XMLPREVIER   *PGM    RPG      script member in a subfile                 */
/* XMLPREVIED   *FILE   DSPF     display file                               */
/* XMLPREVIEH   *PNLGRP          help panel  HLPID = 'XMLPREVIEW'           */
/* ------------------------------------------------------------------------ */
/* >>PRE-COMPILER<<                                                         */
/*                                                                          */
/*   >>CRTCMD<< CRTCMD       CMD(&LI/&OB) +                                 */
/*                           SRCFILE(&SL/&SF) +                             */
/*                           SRCMBR(&SM);                                   */
/*                                                                          */
/*   >>COMPILE<<                                                            */
/*     >>PARM<< PGM(*LIBL/XMLPREVIEC);                                      */
/*     >>PARM<< ALWLMTUSR(*NO);                                             */
/*     >>PARM<< HLPID(XMLPREVIEW);                                          */
/*     >>PARM<< VLDCKR(*LIBL/XMLPREVIEV);                                   */
/*     >>PARM<< MODE( *PROD *DEBUG *SERVICE);                               */
/*     >>PARM<< ALLOW( *BPGM *IPGM *EXEC *INTERACT +                        */
/*                     *BATCH *BREXX *IREXX *BMOD *IMOD);                   */
/*     >>PARM<< HLPPNLGRP(*LIBL/XMLPREVIEH);                                */
/*     >>PARM<< PRDLIB(&LI);                                                */
/*     >>PARM<< TEXT(*SRCMBRTXT);                                           */
/*   >>END-COMPILE<<                                                        */
/*                                                                          */
/*   >>EXECUTE<<                                                            */
/*                                                                          */
/* >>END-PRE-COMPILER<<                                                     */
/* ------------------------------------------------------------------------ */
             CMD        PROMPT('Preview XML before install')

             PARM       KWD(UPLOADMBR) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Uploaded member name')

             PARM       KWD(UPLOADSRCF) TYPE(QUAL1) MIN(1) +
                          PROMPT('Upload source file')

             PARM       KWD(OUTPUTSRCF) TYPE(*NAME) LEN(10) +
                          DFT(*DEFAULTS) SPCVAL((*DEFAULTS +
                          '*DEFAULTS ')) MIN(0) PROMPT('Output to +
                          this source file')

             PARM       KWD(TGTRLS) TYPE(*CHAR) LEN(10) +
                          DFT(*DEFAULTS) MIN(0) +
                          SPCVAL((*DEFAULTS '*DEFAULTS ')) +
                          PROMPT('Target release')

/* ----------------------------------------------------------------- */
 QUAL1:      QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL)) PROMPT('Library:')
