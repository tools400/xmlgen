**free
//%METADATA                                                      *
// %TEXT validate selected script and members           jcr      *
//%EMETADATA                                                     *
//---------------------------------------------------------------------------------------------
// xmlgenrv - selected script validity checker
// Copyright (C) 06/19/2001  Craig Rutledge   <craig_rutledge@mohawkind.com>
//
// This program is free software, you can redistribute it and/or modify it under the terms
// of the GNU General Public License as published by the Free Software Foundation.
//
//---------------------------------------------------------------------------------------------
//
// Verify script member exists in selected library
// Verify TO lib and source file exist.
// Verify all source members in script member exist in selected source file.
// Verify all QCMDEXC statements are valid.
//
//---------------------------------------------------------------------------------------------
// >>PRE-COMPILER<<
//   >>CRTCMD<< CRTRPGMOD    MODULE(&LI/&OB) +
//                           SRCFILE(&SL/&SF) SRCMBR(&SM);
//   >>COMPILE<<
//     >>PARM<< TRUNCNBR(*NO);
//     >>PARM<< DBGVIEW(*LIST);
//     >>PARM<< OPTION(*EVENTF);
//   >>END-COMPILE<<
//   >>EXECUTE<<
//   >>CMD<<    CRTPGM       PGM(&LI/&OB) +
//                           MODULE(&LI/XMLGENRV          +
//                                  &LI/XMLGENRS     )    +
//                           TEXT(*ENTMODTXT) +
//                           ACTGRP(*NEW) +
//                           DETAIL(*BASIC);
// >>END-PRE-COMPILER<<
//--------------------------------------------------------------------------------------------
/copy 'qxmlgen/copyright.rpgleinc'

//---------------------------------------------------------------------------------------------
//  Imported procedures and functions:
//---------------------------------------------------------------------------------------------
/copy 'qxmlgen/xmlgenrs_h.rpgleinc'

//--------------------------------------------------------------------
// create parm prototypes
//--------------------------------------------------------------------

dcl-pr qcapcmd extpgm('QCAPCMD');
  i_cmd         char(32702) options(*varsize) const;
  i_len         int(10) const;
  i_optCtrBlk   char(32767) options(*varsize) const;
  i_optCtrBlkLn int(10) const;
  i_optCtrBlkFt char(8) const;
  o_chgCmd      char(32702) options(*varsize);
  i_chgCmdLen   int(10) const;
  o_chgCmdAvl   int(10);
  io_errCode    char(32767) options(*varsize);
end-pr;

dcl-pr qsqchks extpgm('QSQCHKS');
  i_sqlStmt    char(32767) options(*varsize) const;
  i_sqlStmtLen int(10) const;
  i_numRcds    int(10) const;
  i_language   char(10) const;
  i_options    char(32767) options(*varsize) const;
  o_stmtInf    char(32767) options(*varsize);
  i_stmtInfLen int(10) const;
  o_numRcdsPrc int(10);
  io_errorCode char(32767) options(*varsize);
end-pr;

//--------------------------------------------------------------------

//  *ENTRY parameters:
dcl-ds qSrcFile_t qualified template;
  name char(10);
  lib  char(10);
end-ds;
dcl-pi *n;
  ScriptMbr   char(10); // script driver mbr
  ScriptSrcFL likeds(qSrcFile_t); // script driver file
  ToSrcFL     likeds(qSrcFile_t); // Output XML source
end-pi;

//  fields & constants:
dcl-c cEOF *on;

// a line from the script
dcl-s xscriptsource varchar(240) inz;

// a XMLGEN command from the script
dcl-s string varchar(2000) inz; // like(string_t)

// values extracted from mbr script command
dcl-s xmbr char(10) inz; // member name
dcl-s xmbratr char(10) inz; // source mbr attr
dcl-s xfromsrcf char(10) inz; // copy from src file
dcl-s xfromsrcl char(10) inz; // copy from src lib
dcl-s xtosrcf char(10) inz; // copy to src file
dcl-s xobjtype char(7) inz; // object type
dcl-s xgencrt char(4) inz; // gen compile code?
dcl-s xparam char(200) inz; // optional parameter
dcl-s xcondition char(10) inz; // compile condition
dcl-s xcommand varchar(2000) inz; // cl/sql command  like(string_t)

// qcapcmd API
dcl-ds optCtrlBlk qualified;
  typeCmdPrc   int(10) pos(1) inz(4); // cl command stmRADDAT
  DBCS_data    char(1) pos(5) inz('0'); // ignore DBCS
  prmtAction   char(1) pos(6) inz('0'); // never prompt
  cmdStrSyntax char(1) pos(7) inz('0'); // system syntax RADDAT
  msgRtvKey    char(4) pos(8) inz(*blanks); // no msg key
  res_01       char(9) pos(12) inz(*allx'00');
end-ds;
dcl-s chgCmd char(128) inz;
dcl-s chgCmdAvl int(10) inz;

// qsqchks API
dcl-ds sqlOption;
  sqlOption_numKey  int(10) inz(1);
  sqlOption_key     int(10) inz(1);
  sqlOption_dataLen int(10) inz(10);
  sqlOption_data    char(10) inz('*SQL');
end-ds;

dcl-ds sqlStmtInf;
  sqlStmtInf_msgF         char(10) inz;
  sqlStmtInf_msgFLib      char(10) inz;
  sqlStmtInf_numStmt      int(10) inz;
  sqlStmtInf_bytRet       int(10) inz;
  sqlStmtInf_rcdNbrFB     int(10) inz;
  sqlStmtInf_colNbrFB     int(10) inz;
  sqlStmtInf_rcdNbrLB     int(10) inz;
  sqlStmtInf_colNbrLB     int(10) inz;
  sqlStmtInf_rcdNbrErr    int(10) inz;
  sqlStmtInf_colNbrErr    int(10) inz;
  sqlStmtInf_msgID        char(7) inz;
  sqlStmtInf_state        char(5) inz;
  sqlStmtInf_lenMsgRplTxt int(10) inz;
  sqlStmtInf_msgRplTxt    char(128) inz;
end-ds;

dcl-s sqlNumRcd int(10) inz;

dcl-ds errorCode;
  errorCode_bytPrv  int(10) inz(%size(errorCode));
  errorCode_bytAvl  int(10) inz;
  errorCode_excpID  char(7) inz;
  errorCode_res     char(1) inz;
  errorCode_excpDta char(128) inz;
end-ds;

//--------------------------------------------------------------------
// Program status data structure.
//--------------------------------------------------------------------
dcl-ds sds psds;
  sds_pgmName  char(10);
  sds_status   zoned(5: 0);
  sds_prvStat  zoned(5: 0);
  sds_lastSeq  char(8);
  sds_lastSubR char(8);
  sds_numParm  zoned(3: 0);
  sds_msgID    char(7);
  sds_MiInstr  char(4);
  sds_wrkArea  char(30);
  sds_lib      char(10);
  sds_msgText  char(80);
end-ds;

//---------------------------------------------------------------------
// Ensure field sizes between modules.
//---------------------------------------------------------------------

ensureStringLength(%size(string_t));

assert(%size(string_t) = %size(string)     :
      'Size of ''string'' does not match'  :
      sds_pgmName                          );
assert(%size(string_t) = %size(xcommand)   :
      'Size of ''xcommand'' does not match':
      sds_pgmName                          );

//---------------------------------------------------------------------
// Verify target source file and library exists.
//---------------------------------------------------------------------

//  Library:
if (not chkobj(ToSrcFL.lib: '*LIBL': '*LIB'));
  sndMessage('CPF9897'              :
             '0000 Library ' +
              %trim(ToSrcFL.lib) +
             ' was not found'       :
             '*DIAG'                );
  sndMessage('CPF0002' :
             ''        :
             '*ESCAPE' );
endif;

//  File:
if (not chkobj(ToSrcFL.name: ToSrcFL.lib:'*FILE'));
  sndMessage('CPF9897'              :
             '0000 Source File ' +
              %trim(ToSrcFL.name) +
             ' was not found in ' +
              %trim(ToSrcFL.lib)    :
             '*DIAG'                );
  sndMessage('CPF0002' :
             ''        :
             '*ESCAPE' );
endif;

//---------------------------------------------------------------------
// Open script file.
//---------------------------------------------------------------------
if (not openScript(ScriptSrcFL.name :
                   ScriptSrcFL.lib  :
                   ScriptMbr        ));
  sndMessage('CPF0002' :
             ''        :
             '*ESCAPE' );
endif;

//    ----------------------------------------------------------------
//    read through the member loading source record to outfile
//    ----------------------------------------------------------------
dow (readScript(xscriptsource) <> cEOF);

  //---------------------------------------------------------------------
  // Spin through driver file and load data from tags as the occur.
  //      XMLGENMBR  XMBR(XMLGEN) XMBRATR(CLP) XFROMSRCF(JCLSRC) +
  //                   XFROMSRCL(JCRCMDS) XTOSRCF(QCLSRC) +
  //                   XOBJTYPE(*PGM) +
  //                   XPARAM(OPTION(*SRCDBG) USRPRF(*OWNER)) +
  //                   XGENCRT(*YES)
  //
  //      XMLGENCMD  XCMD(CRTDTAARA DTAARA(&TOLIB/TEST) +
  //                   TYPE(*CHAR) LEN(10) VALUE(A))
  //
  //      XMLGENSQL  XCMD(SELECT * FROM MYLIB/MYFILE)
  //---------------------------------------------------------------------
  // Check for XMLGEN command ...
  select;
  // ... XMLGENMBR
  when (%scan('XMLGENMBR':ucase(xscriptsource)) > 0);
    string = loadScriptString(xscriptsource);  // load into one string
    string = fmtClCmd(string);  // format command
    string = rmvClRem(string);  // remove comment
    if (string <> '');
      exsr srParseMbrVal;  // extract mbr values
      exsr srVldMbr;  // validate mbr
    endif;
  // ... XMLGENCMD
  when (%scan('XMLGENCMD':ucase(xscriptsource)) > 0);
    string = loadScriptString(xscriptsource);  // load into one string
    string = fmtClCmd(string);  // format command
    string = rmvClRem(string);  // remove comment
    if (string <> '');
      exsr srParseCmdVal;  // extract cmd values
      exsr srVldCmd;  // validate cmd
    endif;
  // ... XMLGENSQL
  when (%scan('XMLGENSQL':ucase(xscriptsource)) > 0);
    string = loadScriptString(xscriptsource);  // load into one string
    string = fmtClCmd(string);  // format command
    string = rmvClRem(string);  // remove comment
    if (string <> '');
      exsr srParseSqlVal;  // extract sql values
      exsr srVldSql;  // validate sql
    endif;
  // ... others
  other;
    string = '';
  endsl;

enddo;

closeScript();

*inlr=*on;
return;

//---------------------------------------------------------------------------------------------
// extract values from XMLGENMBR script command
//---------------------------------------------------------------------------------------------
begsr srParseMbrVal;

  xcondition = getKwdData('XCND'    : string);

  if (xcondition = '');
    xcondition = '*NONE';
  else;
    xcondition = rmvQuotes(%trim(xcondition));
  endif;

  xmbr      = getKwdData('XMBR'   : string);

  xmbratr   = getKwdData('XMBRATR': string);

  xfromsrcf = getKwdData('XFROMSRCF': string);

  xfromsrcl = getKwdData('XFROMSRCL': string);

  xtosrcf   = getKwdData('XTOSRCF'  : string);

  xobjtype  = getKwdData('XOBJTYPE' : string);

  xgencrt   = getKwdData('XGENCRT'  : string);

  xparam    = getKwdData('XPARAM'   : string);

  if (xparam = '*BLANK');
    xparam = ' ';
  else;
    xparam = rmvQuotes(%trim(xparam));
  endif;

endsr;

//---------------------------------------------------------------------------------------------
// extract values from XMLGENCMD script command
//---------------------------------------------------------------------------------------------
begsr srParseCmdVal;

  xcondition = getKwdData('XCND'    : string);

  if (xcondition = '');
    xcondition = '*NONE';
  else;
    xcondition = rmvQuotes(%trim(xcondition));
  endif;

  xcommand  = getKwdData('XCMD'     : string);

  xcommand = rmvQuotes(xcommand);

  xcommand = replace('&TOLIB'  :
                     xcommand  :
                     'QUSRSYS' );

endsr;

//---------------------------------------------------------------------------------------------
// extract values from XMLGENSQL script command
//---------------------------------------------------------------------------------------------
begsr srParseSqlVal;

  xcondition = getKwdData('XCND'    : string);

  if (xcondition = '');
    xcondition = '*NONE';
  else;
    xcondition = rmvQuotes(%trim(xcondition));
  endif;

  xcommand  = getKwdData('XSQL'     : string);

  xcommand = rmvQuotes(xcommand);

  xcommand = rmvDblQuotes(xcommand);

  xcommand = replace('&TOLIB'  :
                     xcommand  :
                     'QUSRSYS' );

endsr;
//--------------------------------------------------------------------
// Check of file, lib, member exist.
//--------------------------------------------------------------------
begsr srVldMbr;

  //  Library:
  if (not chkobj(xfromsrcl: '*LIBL': '*LIB'));
    sndMessage('CPF9897'              :
               '0000 Library ' +
                %trim(xfromsrcl) +
               ' was not found'       :
               '*DIAG'                );
    sndMessage('CPF0002' :
               ''        :
               '*ESCAPE' );
  endif;

  //  File:
  if (not chkobj(xfromsrcf: xfromsrcl: '*FILE'));
    sndMessage('CPF9897'              :
               '0000 Source File ' +
                %trim(xfromsrcf) +
               ' was not found in ' +
                %trim(xfromsrcl)      :
               '*DIAG'                );
    sndMessage('CPF0002' :
               ''        :
               '*ESCAPE' );
  endif;

  //  Member:
  if (not chkobj(xfromsrcf:xfromsrcl:'*FILE': xmbr));
    sndMessage('CPF9897'              :
               '0000 Member ' +
                %trim(xmbr) +
               ' was not found in ' +
                %trim(xfromsrcl) + '/' +
                %trim(xfromsrcf)      :
               '*DIAG'                );
    sndMessage('CPF0002' :
               ''        :
               '*ESCAPE' );
  endif;

endsr;

//---------------------------------------------------------------------------------------
// validate cl command
//---------------------------------------------------------------------------------------
begsr srVldCmd;

  callp(e) qcapcmd(xcommand
                   : %len(xcommand)
                   : optCtrlBlk
                   : %size(optCtrlBlk)
                   : 'CPOP0100'
                   : chgCmd
                   : 0
                   : chgCmdAvl
                   : errorCode);
  if (errorCode_bytAvl <> 0);
    sndMessage('CPF9897'              :
               '0000 Invalid command: ' +
                %trim(xcommand)       :
               '*DIAG'                );
    sndMessage('CPF0002' :
               ''        :
               '*ESCAPE' );
  endif;

endsr;

//---------------------------------------------------------------------------------------
// extract command from string, check with qsqchks API
//---------------------------------------------------------------------------------------
begsr srVldSql;

  reset sqlOption;
  reset sqlStmtInf;
  reset sqlNumRcd;
  reset errorCode;
  qsqchks(xcommand          :
          %size(xcommand)   :
          1                 :
          '*NONE'           :
          sqlOption         :
          sqlStmtInf        :
          %size(sqlStmtInf) :
          sqlNumRcd         :
          errorCode         );
  if (sqlStmtInf_msgID <> ' ');
    sndMessage(sqlStmtInf_msgID                 :
               %subst(sqlStmtInf_msgRplTxt    :
                      1                       :
                      sqlStmtInf_lenMsgRplTxt ) :
               '*DIAG'                          :
               sqlStmtInf_msgF                  :
               sqlStmtInf_msgFLib               );
    sndMessage('CPF0002' :
               ''        :
               '*ESCAPE' );
  endif;
endsr;

