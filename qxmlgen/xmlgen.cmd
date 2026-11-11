      /*%METADATA                                                     */
      /* %TEXT Generate xml source member for download        jcr     */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------ */
/* XMLGEN - GENERATE XML MBR FOR DOWNLOAD TO PC                             */
/*                                                                          */
/* Copyright (C) 2001       Craig Rutledge    <craig_rutledge@mohawkind.com> */
/* This utility is an Open Source collaborative effort.                     */
/* Martin Rowe  <Martin@dbg400.net>        scripting cmd prompts            */
/* David George <webmaster@400times.co.uk> intellectual input               */
/*                                                                          */
/* This program is free software, you can redistribute it and/or modify it  */
/* under the terms of the GNU General Public License as published by        */
/* the Free Software Foundation.  See GNU General Public License for detail. */
/* ------------------------------------------------------------------------ */
/* Related Objects:                                                         */
/*                                                                          */
/* XMLGENC    *PGM    CLP      command processing program                   */
/* XMLGENR    *PGM    RPG      generate xml source member                   */
/* XMLGENRV   *PGM    RPG      validity checker for key selected            */
/* QXMLGENS   *FILE   SRC-PF   source/object info scripts                   */
/* XMLGENP    *PNLGRP          help panel  HLPID = 'XMLGEN'                 */
/* XMLGENINC  *CMD    CMD      script propmt command                        */
/* XMLGENMBR  *CMD    CMD      script propmt command                        */
/* XMLGENCMD  *CMD    CMD      script propmt command                        */
/* XMLGENSQL  *CMD    CMD      script propmt command                        */
/* ------------------------------------------------------------------------ */
/* >>PRE-COMPILER<<                                                         */
/*   >>CRTCMD<< CRTCMD       CMD(&LI/&OB) +                                 */
/*                           SRCFILE(&SL/&SF) +                             */
/*                           SRCMBR(&SM);                                   */
/*   >>IMPORTANT<<                                                          */
/*     >>PARM<< PGM(*LIBL/XMLGENC);                                         */
/*     >>PARM<< ALWLMTUSR(*NO);                                             */
/*     >>PARM<< HLPID(XMLGEN);                                              */
/*     >>PARM<< VLDCKR(*LIBL/XMLGENRV);                                     */
/*     >>PARM<< MODE( *PROD *DEBUG *SERVICE);                               */
/*     >>PARM<< ALLOW( *BPGM *IPGM *EXEC *INTERACT +                        */
/*                     *BATCH *BREXX *IREXX *BMOD *IMOD);                   */
/*     >>PARM<< HLPPNLGRP(*LIBL/XMLGENP);                                   */
/*     >>PARM<< PRDLIB(&LI);                                                */
/*     >>PARM<< TEXT(*SRCMBRTXT);                                           */
/*   >>END-IMPORTANT<<                                                      */
/*   >>EXECUTE<<                                                            */
/* >>END-PRE-COMPILER<<                                                     */
/* ------------------------------------------------------------------------ */
             CMD        PROMPT('Generate XML download mbrs')

/* ----------------------------------------------------------------- */
             PARM       KWD(XMLSCRIPT) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Script member name')

             PARM       KWD(SCRIPTSRCF) TYPE(QUAL1) MIN(0) +
                          PROMPT('Script source file')

             PARM       KWD(SRCTOFILE) TYPE(QUAL2) MIN(0) +
                          PROMPT('Source file to put XML member')

             PARM       KWD(XMLMBR) TYPE(*NAME) LEN(10) MIN(0) +
                          DFT(*SCRIPT) +
                          SPCVAL(*SCRIPT) +
                          PROMPT('XML output member name')

             PARM       KWD(ENCODING ) TYPE(*CHAR) LEN(10) MIN(0) +
                          DFT('ISO-8859-1')               +
                          RSTD(*YES)                      +
                          VALUES(('ISO-8859-1')           +
                                 ('UTF-8'     ))          +
                          PROMPT('Encoding of XML file')

             PARM       KWD(AUTHOR   ) TYPE(*CHAR) LEN(20) MIN(0) +
                          DFT('Craig Rutledge')           +
                          PROMPT('Application author')

/* ----------------------------------------------------------------- */
 QUAL1:      QUAL       TYPE(*NAME) LEN(10) DFT(QXMLGENS)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL)) PROMPT('Library')
 QUAL2:      QUAL       TYPE(*NAME) LEN(10) DFT(QXML)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL)) PROMPT('Library')
