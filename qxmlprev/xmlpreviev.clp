      /*%METADATA                                                     */
      /* %TEXT Validity checker for XMLPREVIEW command        jcr     */
      /*%EMETADATA                                                    */
/*--------------------------------------------------------------------------*/
/* XMLPREVIEV- VALIDITY CHECK FOR XMLPREVIEW COMAND                         */
/* Copyright (C) 7/18/2001  Craig Rutledge    <craig_rutledge@mohawkind.com>*/
/*                                                                          */
/* This program is free software, you can redistribute it and/or modify it  */
/* under the terms of the GNU General Public License as published by        */
/* the Free Software Foundation.  See GNU General Public License for detail.*/
/*--------------------------------------------------------------------------*/
/* Validations:                                                      */
/* Source file/member and library exist.                             */
/*-------------------------------------------------------------------*/
    PGM  PARM(&MBR &FILE_LIB &OVRSRCFIL &TGTRLS)
    DCL  &MBR          *CHAR  10      /* member                    */
    DCL  &FILE_LIB     *CHAR  20      /* source file library       */
    DCL  &OVRSRCFIL    *CHAR  10
    DCL  &TGTRLS       *CHAR  10
    DCL  &SFILE        *CHAR  10
    DCL  &SLIB         *CHAR  10
    CHGVAR &SFILE   %SST(&FILE_LIB 1 10)
    CHGVAR &SLIB    %SST(&FILE_LIB 11 10)

    CHKOBJ OBJ(&SLIB/&SFILE) OBJTYPE(*FILE) MBR(&MBR)
    MONMSG MSGID(CPF9810) EXEC(DO)    /* Library not found         */
    SNDPGMMSG  MSGID(CPD0006) MSGF(QCPFMSG) MSGDTA('0000 +
    Library ' *CAT &SLIB *TCAT ' was not found.') +
    MSGTYPE(*DIAG)
    SNDPGMMSG  MSGID(CPF0002) MSGF(QCPFMSG) MSGTYPE(*ESCAPE)
    ENDDO

    MONMSG MSGID(CPF9801) EXEC(DO)    /* Source file was not found */
    SNDPGMMSG  MSGID(CPD0006) MSGF(QCPFMSG) MSGDTA('0000 +
    Source file ' *CAT &SFILE *TCAT ' was not found +
    in library ' *CAT &SLIB *TCAT '.') +
    MSGTYPE(*DIAG)
    SNDPGMMSG  MSGID(CPF0002) MSGF(QCPFMSG) MSGTYPE(*ESCAPE)
    ENDDO

    MONMSG MSGID(CPF9815) EXEC(DO)    /* Member was not found      */
    IF (&SLIB ='*LIBL     ') DO
    RTVOBJD    OBJ(&SFILE) OBJTYPE(*FILE) RTNLIB(&SLIB)
    MONMSG     MSGID(CPF0000)
    ENDDO
    SNDPGMMSG  MSGID(CPD0006) MSGF(QCPFMSG) MSGDTA('0000 +
    Member ' *CAT &MBR *TCAT ' was not +
    found in source file ' *CAT &SLIB *TCAT '/+
    ' *CAT &SFILE *TCAT '.') +
    MSGTYPE(*DIAG)
    SNDPGMMSG  MSGID(CPF0002) MSGF(QCPFMSG) MSGTYPE(*ESCAPE)
    ENDDO
    ENDPGM
