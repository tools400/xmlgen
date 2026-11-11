      /*%METADATA                                                     */
      /* %TEXT Preview uploaded xml install members           jcr     */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------ */
/* XMLPREVIEC- PREVIEW UPLOAD XML MEMBERS BEFORE INSTALL                    */
/* Copyright (C) 7/18/2001  Craig Rutledge    <craig_rutledge@mohawkind.com> */
/*                                                                          */
/* This program is free software, you can redistribute it and/or modify it  */
/* under the terms of the GNU General Public License as published by        */
/* the Free Software Foundation.  See GNU General Public License for detail. */
/* ------------------------------------------------------------------------ */
             PGM  PARM(&XMLMBR &XMLSFL &USRSRCF &TGTRLS)
             DCL  &XMLMBR     *CHAR    10 /* UPLOADED MEMBER NAME      */
             DCL  &XMLSFL     *CHAR    20 /* XML SOURCE FILE LIB       */
             DCL  &USRSRCF    *CHAR    10 /* USER SELECTED OUTPUT SRCF */
             DCL  &TGTRLS     *CHAR    10 /* TGTRLS TO COMPILE FOR     */
             DCL  &XMLSFIL    *CHAR    10
             DCL  &XMLSLIB    *CHAR    10
             DCL  &XMLINSTAL  *CHAR     1
             DCL  &CONDITIONS *CHAR   128

             CHGVAR     VAR(&XMLSFIL) VALUE(%SST(&XMLSFL 1 10))
             CHGVAR     VAR(&XMLSLIB) VALUE(%SST(&XMLSFL 11 10))

             IF         COND(&XMLSLIB = '*LIBL     ') THEN(DO)
             RTVOBJD    OBJ(&XMLSFIL) OBJTYPE(*FILE)  RTNLIB(&XMLSLIB)
             MONMSG     MSGID(CPF0000)
             ENDDO

             OVRDBF     FILE(XMLINPUT) TOFILE(&XMLSLIB/&XMLSFIL) +
                          MBR(&XMLMBR)
             CALL       PGM(XMLPREVIER) PARM(&XMLMBR &XMLSFIL +
                          &XMLSLIB &USRSRCF &TGTRLS &XMLINSTAL)

  /* --------------------------------------------------------------------- */
  /* if user has selected to run install.                                  */
  /* Create source file in qtemp                                           */
  /* Call RPG program to read and extract installer code                   */
  /* compile and run installer code                                        */
  /* --------------------------------------------------------------------- */
             IF (&XMLINSTAL = 'Y') DO
             CRTSRCPF   FILE(QTEMP/XMLEXTRACT) RCDLEN(112)
             MONMSG CPF0000
             ADDPFM     FILE(QTEMP/XMLEXTRACT) MBR(XMLEXTRACT)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(QTEMP/XMLEXTRACT) MBR(XMLEXTRACT))
             OVRDBF     FILE(INSTALLOUT) TOFILE(QTEMP/XMLEXTRACT) +
                          MBR(XMLEXTRACT)
             CALL XMLPREVINR          /* LOAD INSTALLER CODE */
             CRTBNDRPG  PGM(QTEMP/XMLEXTRACT) +
                          SRCFILE(QTEMP/XMLEXTRACT) +
                          DBGVIEW(*SOURCE) OUTPUT(*NONE) +
                          TGTRLS(*CURRENT)
             DLTOVR *ALL

  /* --------------------------------------------------------------------- */
  /* Many users do use the IBM default source file names, instead they     */
  /* prefer to have all different source member type in one file.          */
  /*   (there have been many requests for this!)                           */
  /*                                                                       */
  /* if user has selected to use *DEFAULTS source files for output,        */
  /*   (Note: *DEFAULTS means to use source files in the upload            */
  /*  then call installer program passing only first 3 parms.              */
  /*                                                                       */
  /* If user has selected a single target source file, then call installer */
  /* program passing all 4 parms.                                          */
  /* --------------------------------------------------------------------- */
             IF         COND(&USRSRCF *EQ '*DEFAULTS ') THEN(DO)
             CHGVAR     VAR(&USRSRCF) VALUE(' ')
             ENDDO
             CHGVAR     VAR(&CONDITIONS) VALUE(' ')
             IF         COND(&TGTRLS  *EQ '*DEFAULTS ') THEN(DO)
             CHGVAR     VAR(&TGTRLS ) VALUE(' ')
             ENDDO

             IF         COND(&USRSRCF *EQ ' ' *AND &TGTRLS *EQ ' ') THEN(DO)
                CALL       PGM(QTEMP/XMLEXTRACT) +
                           PARM(&XMLMBR &XMLSFIL &XMLSLIB)
                GOTO       CMDLBL(EXIT)
             ENDDO

             IF         COND(&USRSRCF *NE ' ' *AND &TGTRLS *EQ ' ') THEN(DO)
                CALL       PGM(QTEMP/XMLEXTRACT) +
                           PARM(&XMLMBR &XMLSFIL &XMLSLIB &USRSRCF)
                GOTO       CMDLBL(EXIT)
             ENDDO

             CALL       PGM(QTEMP/XMLEXTRACT) +
                        PARM(&XMLMBR &XMLSFIL &XMLSLIB &USRSRCF &CONDITIONS &TGTRLS)
EXIT:
             ENDDO
             ENDPGM
