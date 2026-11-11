      /*%METADATA                                                     */
      /* %TEXT Generate xml members for download              jcr     */
      /*%EMETADATA                                                    */
/* ---------------------------------------------------------------------- -- */
/* XMLGENC - GENERATE XML MBR FROM SELECTED GROUP ID.                        */
/*                                                                           */
/* Copyright (C) 6/19/2001  Craig Rutledge    <craig_rutledge@mohawkind.com> */
/*                                                                           */
/* This program is free software, you can redistribute it and/or modify it   */
/* under the terms of the GNU General Public License as published by         */
/* the Free Software Foundation.  See GNU General Public License for detail. */
/* ------------------------------------------------------------------------- */
/* >>PRE-COMPILER<<                                                          */
/*   >>CRTCMD<< CRTCLPGM     PGM(&LI/&OB) +                                  */
/*                           SRCFILE(&SL/&SF) SRCMBR(&SM);                   */
/*   >>IMPORTANT<<                                                           */
/*     >>PARM<< PGM(&LI/&OB);                                                */
/*     >>PARM<< OPTION(*LSTDBG);                                             */
/*   >>END-IMPORTANT<<                                                       */
/*   >>EXECUTE<<                                                             */
/* >>END-PRE-COMPILER<<                                                      */
/* ------------------------------------------------------------------------- */
             PGM  PARM(&SCRIPTMBR &SCRIPTSFL &XMLTOSFL &XMLMBR &ENCODING &AUTHOR)
             DCL  &SCRIPTMBR  *CHAR    10 /* MEMBER NAME IN SCRIPT FILE */
             DCL  &SCRIPTSFL  *CHAR    20 /* SCRIPT SOURCE FILE LIB     */
             DCL  &SCRIPTSFIL *CHAR    10
             DCL  &SCRIPTSLIB *CHAR    10
             DCL  &XMLTOSFL   *CHAR    20 /* TO SOURCE FILE   LIB        */
             DCL  &XMLTOSFIL  *CHAR    10
             DCL  &XMLTOSLIB  *CHAR    10
             DCL  &XMLMBR     *CHAR    10
             DCL  &ENCODING   *CHAR    10
             DCL  &AUTHOR     *CHAR    20
             DCL  &TEXT       *CHAR    50

             CHGVAR     VAR(&SCRIPTSFIL) VALUE(%SST(&SCRIPTSFL  1 10))
             CHGVAR     VAR(&SCRIPTSLIB) VALUE(%SST(&SCRIPTSFL 11 10))
             CHGVAR     VAR(&XMLTOSFIL ) VALUE(%SST(&XMLTOSFL   1 10))
             CHGVAR     VAR(&XMLTOSLIB ) VALUE(%SST(&XMLTOSFL  11 10))

             IF         COND(&XMLMBR = '*SCRIPT') THEN(DO)
             CHGVAR     VAR(&XMLMBR) VALUE(&SCRIPTMBR)
             ENDDO

             IF         COND(&SCRIPTSLIB = '*LIBL     ') THEN(DO)
             RTVOBJD    OBJ(&SCRIPTSFIL) OBJTYPE(*FILE)  RTNLIB(&SCRIPTSLIB)
             MONMSG     MSGID(CPF0000)
             ENDDO

             IF         COND(&XMLTOSLIB = '*LIBL     ') THEN(DO)
             RTVOBJD    OBJ(&XMLTOSFIL) OBJTYPE(*FILE) RTNLIB(&XMLTOSLIB)
             MONMSG     MSGID(CPF0000)
             ENDDO

             SNDPGMMSG  MSGID(CPF9898) MSGF(QCPFMSG) MSGDTA('XML +
                          code generation - in progress') +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)

/* ----------------------------------------------------------------- */
/* CREATE SELECTED OUTFILE AND MEMBER (IF REQUIRED)                  */
/* ----------------------------------------------------------------- */
             ADDPFM     FILE(&XMLTOSLIB/&XMLTOSFIL) MBR(&SCRIPTMBR)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(&XMLTOSLIB/&XMLTOSFIL) MBR(&SCRIPTMBR))

             CHGVAR     VAR(&TEXT) VALUE('XML data for group ' *CAT +
                          &SCRIPTMBR *TCAT '.')

             CHGPFM     FILE(&XMLTOSLIB/&XMLTOSFIL) MBR(&SCRIPTMBR) +
                          SRCTYPE(XML) TEXT(&TEXT)

/* ----------------------------------------------------------------- */
/* CALL PROGRAM TO GENERATE XML SOURCE                               */
/* ----------------------------------------------------------------- */
             CALL XMLGENR PARM(&SCRIPTSFIL +
                               &SCRIPTSLIB +
                               &SCRIPTMBR  +
                               &XMLTOSFIL  +
                               &XMLTOSLIB  +
                               &XMLMBR     +
                               &SCRIPTMBR  +
                               &ENCODING   +
                               &AUTHOR     )

             SNDPGMMSG  MSG('XML generation for ' *CAT &SCRIPTMBR *TCAT ' +
                          in ' *CAT &XMLTOSLIB *TCAT '/' *CAT &XMLTOSFIL +
                          *TCAT ' - completed.')
             ENDPGM
