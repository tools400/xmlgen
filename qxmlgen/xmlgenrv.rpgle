      *%METADATA                                                       *
      * %TEXT validate selected script and members           jcr       *
      *%EMETADATA                                                      *
      *---------------------------------------------------------------------------------------------
      * xmlgenrv - selected script validity checker
      * Copyright (C) 06/19/2001  Craig Rutledge   <craig_rutledge@mohawkind.com>
      *
      * This program is free software, you can redistribute it and/or modify it under the terms
      * of the GNU General Public License as published by the Free Software Foundation.
      *
      *---------------------------------------------------------------------------------------------
      *
      * Verify script member exists in selected library
      * Verify TO lib and source file exist.
      * Verify all source members in script member exist in selected source file.
      * Verify all QCMDEXC statements are valid.
      *
      *---------------------------------------------------------------------------------------------
      * >>PRE-COMPILER<<
      *   >>CRTCMD<< CRTRPGMOD    MODULE(&LI/&OB) +
      *                           SRCFILE(&SL/&SF) SRCMBR(&SM);
      *   >>COMPILE<<
      *     >>PARM<< TRUNCNBR(*NO);
      *     >>PARM<< DBGVIEW(*LIST);
      *     >>PARM<< OPTION(*EVENTF);
      *   >>END-COMPILE<<
      *   >>EXECUTE<<
      *   >>CMD<<    CRTPGM       PGM(&LI/&OB) +
      *                           MODULE(&LI/XMLGENRV          +
      *                                  &LI/XMLGENRS     )    +
      *                           TEXT(*ENTMODTXT) +
      *                           ACTGRP(*NEW) +
      *                           DETAIL(*BASIC);
      * >>END-PRE-COMPILER<<
      *--------------------------------------------------------------------------------------------
      /copy 'qxmlgen/copyright.rpgleinc'
      *
      *---------------------------------------------------------------------------------------------
      *  Imported procedures and functions:
      *---------------------------------------------------------------------------------------------
      /copy 'qxmlgen/xmlgenrs_h.rpgleinc'
      *
      *--------------------------------------------------------------------
      * create parm prototypes
      *--------------------------------------------------------------------
      *
     D  qcapcmd        PR                  ExtPgm('QCAPCMD')
     D  i_cmd                     32702A   const  options(*varsize)
     D  i_len                        10I 0 const
     D  i_optCtrBlk               32767A   const  options(*varsize)
     D  i_optCtrBlkLn                10I 0 const
     D  i_optCtrBlkFt                 8A   const
     D  o_chgCmd                  32702A          options(*varsize)
     D  i_chgCmdLen                  10I 0 const
     D  o_chgCmdAvl                  10I 0
     D  io_errCode                32767A          options(*varsize)
      *
     D  qsqchks        PR                  ExtPgm('QSQCHKS')
     D  i_sqlStmt                 32767a   Const  options(*varsize)
     D  i_sqlStmtLen                 10i 0 Const
     D  i_numRcds                    10i 0 Const
     D  i_language                   10a   Const
     D  i_options                 32767a   Const  options(*varsize)
     D  o_stmtInf                 32767a          options(*varsize)
     D  i_stmtInfLen                 10i 0 Const
     D  o_numRcdsPrc                 10i 0
     D  io_errorCode              32767a          options(*varsize)
      *
      *--------------------------------------------------------------------
      *
      *  *ENTRY parameters:
     D ScriptMbr       S             10a
      *
     D ScriptSrcFL     DS
     D  ScriptSrcFL_name...
     D                               10a
     D  ScriptSrcFL_lib...
     D                               10a
      *
     D ToSrcFL         DS
     D  ToSrcFL_name...
     D                               10a
     D  ToSrcFL_lib...
     D                               10a
      *
      *  fields & constants:
     D cEOF            C                       const(*on )
      *
      * a line from the script
     D xscriptsource   S            240A   inz varying
      *
      * a XMLGEN command from the script
     D string          S           2000A   inz varying                          like(string_t)
      *
      * values extracted from mbr script command
     D  xmbr           s             10a   inz                                  member name
     D  xmbratr        s             10a   inz                                  source mbr attr
     D  xfromsrcf      s             10a   inz                                  copy from src file
     D  xfromsrcl      s             10a   inz                                  copy from src lib
     D  xtosrcf        s             10a   inz                                  copy to src file
     D  xobjtype       s              7a   inz                                  object type
     D  xgencrt        s              4a   inz                                  gen compile code?
     D  xparam         s            200a   inz                                  optional parameter
     D  xcondition     s             10a   inz                                  compile condition
     D  xcommand       s           2000A   inz varying                          cl/sql command
     D                                                                          like(string_t)
      *
      * qcapcmd API
     D optCtrlBlk      DS                  qualified
     D  typeCmdPrc             1      4I 0 inz(4)                               cl command stmRADDAT
     D  DBCS_data              5      5A   inz('0')                             ignore DBCS
     D  prmtAction             6      6A   inz('0')                             never prompt
     D  cmdStrSyntax           7      7A   inz('0')                             system syntax RADDAT
     D  msgRtvKey              8     11A   inz(*BLANKS)                         no msg key
     D  res_01                12     20A   inz(*ALLx'00')
     D chgCmd          S            128A   inz
     D chgCmdAvl       S             10I 0 inz
      *
      * qsqchks API
     D sqlOption       ds
     D  sqlOption_numKey...
     D                               10i 0 inz(1)
     D  sqlOption_key...
     D                               10i 0 inz(1)
     D  sqlOption_dataLen...
     D                               10i 0 inz(10)
     D  sqlOption_data...
     D                               10a   inz('*SQL')
      *
     D sqlStmtInf      ds
     D  sqlStmtInf_msgF...
     D                               10a   inz
     D  sqlStmtInf_msgFLib...
     D                               10a   inz
     D  sqlStmtInf_numStmt...
     D                               10i 0 inz
     D  sqlStmtInf_bytRet...
     D                               10i 0 inz
     D  sqlStmtInf_rcdNbrFB...
     D                               10i 0 inz
     D  sqlStmtInf_colNbrFB...
     D                               10i 0 inz
     D  sqlStmtInf_rcdNbrLB...
     D                               10i 0 inz
     D  sqlStmtInf_colNbrLB...
     D                               10i 0 inz
     D  sqlStmtInf_rcdNbrErr...
     D                               10i 0 inz
     D  sqlStmtInf_colNbrErr...
     D                               10i 0 inz
     D  sqlStmtInf_msgID...
     D                                7a   inz
     D  sqlStmtInf_state...
     D                                5a   inz
     D  sqlStmtInf_lenMsgRplTxt...
     D                               10i 0 inz
     D  sqlStmtInf_msgRplTxt...
     D                              128a   inz
      *
     D sqlNumRcd       s             10i 0 inz
      *
     D errorCode       ds
     D  errorCode_bytPrv...
     D                               10i 0 inz(%size(errorCode))
     D  errorCode_bytAvl...
     D                               10i 0 inz
     D  errorCode_excpID...
     D                                7a   inz
     D  errorCode_res...
     D                                1a   inz
     D  errorCode_excpDta...
     D                              128a   inz
      *
      *--------------------------------------------------------------------
      * Program status data structure.
      *--------------------------------------------------------------------
     D sds            sds
     D  sds_pgmName                  10A
     D  sds_status                    5S 0
     D  sds_prvStat                   5S 0
     D  sds_lastSeq                   8A
     D  sds_lastSubR                  8A
     D  sds_numParm                   3S 0
     D  sds_msgID                     7A
     D  sds_MiInstr                   4A
     D  sds_wrkArea                  30A
     D  sds_lib                      10A
     D  sds_msgText                  80A
      *
      *--------------------------------------------------------------------
     C     *entry        plist
     C                   parm                    ScriptMbr                      script driver mbr
     C                   parm                    ScriptSrcFL                    script driver file
     C                   parm                    ToSrcFL                        Output XML source
      *
      *---------------------------------------------------------------------
      * Ensure field sizes between modules.
      *---------------------------------------------------------------------
      *
     C                   callp     ensureStringLength(%size(string_t))
      *
     C                   callp     assert(%size(string_t) = %size(string)     :
     C                                   'Size of ''string'' does not match'  :
     C                                   sds_pgmName                          )
     C                   callp     assert(%size(string_t) = %size(xcommand)   :
     C                                   'Size of ''xcommand'' does not match':
     C                                   sds_pgmName                          )
      *
      *---------------------------------------------------------------------
      * Verify target source file and library exists.
      *---------------------------------------------------------------------
      *
      *  Library:
     C                   if        not chkobj(ToSrcFL_lib: '*LIBL': '*LIB')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Library ' +
     C                                         %trim(ToSrcFL_lib) +
     C                                        ' was not found'       :
     C                                        '*DIAG'                )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
      *  File:
     C                   if        not chkobj(ToSrcFL_name: ToSrcFL_lib:'*FILE')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Source File ' +
     C                                         %trim(ToSrcFL_name) +
     C                                        ' was not found in ' +
     C                                         %trim(ToSrcFL_lib)    :
     C                                        '*DIAG'                )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
      *---------------------------------------------------------------------
      * Open script file.
      *---------------------------------------------------------------------
     C                   if        not openScript(ScriptSrcFL_name :
     C                                            ScriptSrcFL_lib  :
     C                                            ScriptMbr        )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
      *    ----------------------------------------------------------------
      *    read through the member loading source record to outfile
      *    ----------------------------------------------------------------
     C                   dow       readScript(xscriptsource) <> cEOF
      *
      *---------------------------------------------------------------------
      * Spin through driver file and load data from tags as the occur.
      *      XMLGENMBR  XMBR(XMLGEN) XMBRATR(CLP) XFROMSRCF(JCLSRC) +
      *                   XFROMSRCL(JCRCMDS) XTOSRCF(QCLSRC) +
      *                   XOBJTYPE(*PGM) +
      *                   XPARAM(OPTION(*SRCDBG) USRPRF(*OWNER)) +
      *                   XGENCRT(*YES)
      *
      *      XMLGENCMD  XCMD(CRTDTAARA DTAARA(&TOLIB/TEST) +
      *                   TYPE(*CHAR) LEN(10) VALUE(A))
      *
      *      XMLGENSQL  XCMD(SELECT * FROM MYLIB/MYFILE)
      *---------------------------------------------------------------------
      * Check for XMLGEN command ...
     C                   select
      * ... XMLGENMBR
     C                   when      %scan('XMLGENMBR':ucase(xscriptsource)) > 0
     C                   eval      string = loadScriptString(xscriptsource)     load into one string
     C                   eval      string = fmtClCmd(string)                    format command
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   if        string <> ''
     C                   exsr      srParseMbrVal                                extract mbr values
     C                   exsr      srVldMbr                                     validate mbr
     C                   endif
      * ... XMLGENCMD
     C                   when      %scan('XMLGENCMD':ucase(xscriptsource)) > 0
     C                   eval      string = loadScriptString(xscriptsource)     load into one string
     C                   eval      string = fmtClCmd(string)                    format command
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   if        string <> ''
     C                   exsr      srParseCmdVal                                extract cmd values
     C                   exsr      srVldCmd                                     validate cmd
     C                   endif
      * ... XMLGENSQL
     C                   when      %scan('XMLGENSQL':ucase(xscriptsource)) > 0
     C                   eval      string = loadScriptString(xscriptsource)     load into one string
     C                   eval      string = fmtClCmd(string)                    format command
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   if        string <> ''
     C                   exsr      srParseSqlVal                                extract sql values
     C                   exsr      srVldSql                                     validate sql
     C                   endif
      * ... others
     C                   other
     C                   eval      string = ''
     C                   endsl
      *
     C                   enddo
      *
     C                   callp     closeScript
      *
     C                   eval      *inlr=*on
     C                   return
      *
      *---------------------------------------------------------------------------------------------
      * extract values from XMLGENMBR script command
      *---------------------------------------------------------------------------------------------
     C     srParseMbrVal begsr
      *
     C                   eval      xcondition = getKwdData('XCND'    : string)
      *
     C                   if        xcondition = ''
     C                   eval      xcondition = '*NONE'
     C                   else
     C                   eval      xcondition = rmvQuotes(%trim(xcondition))
     C                   endif
      *
     C                   eval      xmbr      = getKwdData('XMBR'   : string)
      *
     C                   eval      xmbratr   = getKwdData('XMBRATR': string)
      *
     C                   eval      xfromsrcf = getKwdData('XFROMSRCF': string)
      *
     C                   eval      xfromsrcl = getKwdData('XFROMSRCL': string)
      *
     C                   eval      xtosrcf   = getKwdData('XTOSRCF'  : string)
      *
     C                   eval      xobjtype  = getKwdData('XOBJTYPE' : string)
      *
     C                   eval      xgencrt   = getKwdData('XGENCRT'  : string)
      *
     C                   eval      xparam    = getKwdData('XPARAM'   : string)
      *
     C                   if        xparam = '*BLANK'
     C                   eval      xparam = ' '
     C                   else
     C                   eval      xparam = rmvQuotes(%trim(xparam))
     C                   endif
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from XMLGENCMD script command
      *---------------------------------------------------------------------------------------------
     C     srParseCmdVal begsr
      *
     C                   eval      xcondition = getKwdData('XCND'    : string)
      *
     C                   if        xcondition = ''
     C                   eval      xcondition = '*NONE'
     C                   else
     C                   eval      xcondition = rmvQuotes(%trim(xcondition))
     C                   endif
      *
     C                   eval      xcommand  = getKwdData('XCMD'     : string)
      *
     C                   eval      xcommand = rmvQuotes(xcommand)
      *
     C                   eval      xcommand = replace('&TOLIB'  :
     C                                                xcommand  :
     C                                                'QUSRSYS' )
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from XMLGENSQL script command
      *---------------------------------------------------------------------------------------------
     C     srParseSqlVal begsr
      *
     C                   eval      xcondition = getKwdData('XCND'    : string)
      *
     C                   if        xcondition = ''
     C                   eval      xcondition = '*NONE'
     C                   else
     C                   eval      xcondition = rmvQuotes(%trim(xcondition))
     C                   endif
      *
     C                   eval      xcommand  = getKwdData('XSQL'     : string)
      *
     C                   eval      xcommand = rmvQuotes(xcommand)
      *
     C                   eval      xcommand = rmvDblQuotes(xcommand)
      *
     C                   eval      xcommand = replace('&TOLIB'  :
     C                                                xcommand  :
     C                                                'QUSRSYS' )
      *
     C                   endsr
      *--------------------------------------------------------------------
      * Check of file, lib, member exist.
      *--------------------------------------------------------------------
     C     srVldMbr      begsr
      *
      *  Library:
     C                   if        not chkobj(xfromsrcl: '*LIBL': '*LIB')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Library ' +
     C                                         %trim(xfromsrcl) +
     C                                        ' was not found'       :
     C                                        '*DIAG'                )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
      *  File:
     C                   if        not chkobj(xfromsrcf: xfromsrcl: '*FILE')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Source File ' +
     C                                         %trim(xfromsrcf) +
     C                                        ' was not found in ' +
     C                                         %trim(xfromsrcl)      :
     C                                        '*DIAG'                )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
      *  Member:
     C                   if        not chkobj(xfromsrcf:xfromsrcl:'*FILE': xmbr)
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Member ' +
     C                                         %trim(xmbr) +
     C                                        ' was not found in ' +
     C                                         %trim(xfromsrcl) + '/' +
     C                                         %trim(xfromsrcf)      :
     C                                        '*DIAG'                )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------
      * validate cl command
      *---------------------------------------------------------------------------------------
     C     srVldCmd      begsr
      *
     C                   callp (e) qcapcmd(xcommand
     C                                     : %len(xcommand)
     C                                     : optCtrlBlk
     C                                     : %size(optCtrlBlk)
     C                                     : 'CPOP0100'
     C                                     : chgCmd
     C                                     : 0
     C                                     : chgCmdAvl
     C                                     : errorCode)
     C                   if        errorCode_bytAvl <> 0
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Invalid command: ' +
     C                                         %trim(xcommand)       :
     C                                        '*DIAG'                )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------
      * extract command from string, check with qsqchks API
      *---------------------------------------------------------------------------------------
     C     srVldSql      begsr
      *
     C                   reset                   sqlOption
     C                   reset                   sqlStmtInf
     C                   reset                   sqlNumRcd
     C                   reset                   errorCode
     C                   callp     qsqchks(xcommand          :
     C                                     %size(xcommand)   :
     C                                     1                 :
     C                                     '*NONE'           :
     C                                     sqlOption         :
     C                                     sqlStmtInf        :
     C                                     %size(sqlStmtInf) :
     C                                     sqlNumRcd         :
     C                                     errorCode         )
     C                   if        sqlStmtInf_msgID <> ' '
     C                   callp     sndMessage(sqlStmtInf_msgID                 :
     C                                        %subst(sqlStmtInf_msgRplTxt    :
     C                                               1                       :
     C                                               sqlStmtInf_lenMsgRplTxt ) :
     C                                        '*DIAG'                          :
     C                                        sqlStmtInf_msgF                  :
     C                                        sqlStmtInf_msgFLib               )
     C                   callp     sndMessage('CPF0002' :
     C                                        ''        :
     C                                        '*ESCAPE' )
     C                   endif
     C                   endsr
      *
