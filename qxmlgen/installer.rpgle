**free
//%METADATA                                                      *
// %TEXT Xml Package Installer                          jcr      *
//%EMETADATA                                                     *
//---------------------------------------------------------------------------------------
// CRTBNDRPG PGM(QTEMP/XMLINST) SRCFILE(ISPHERE/QBUILD) SRCMBR(*PGM)
//---------------------------------------------------------------------------------------
// Parse / Install from xml text into source members and objects.
// Copyright (C) 2001    Craig Rutledge    <craig_rutledge@mohawkind.com>
// Martin Rowe    <Martin@dbg400.net>          scripting cmd prompts
// David George   <webmaster@400times.co.uk>   intellectual input
// Thomas Raddatz <thomas.raddatz@tools400.de> execute SQL statements
// Thomas Raddatz <thomas.raddatz@tools400.de> conditions
// Thomas Raddatz <thomas.raddatz@tools400.de> release
// Thomas Raddatz <thomas.raddatz@tools400.de> retrieve object description
//
// Use xml tags in text to trigger:
// 1. Parse text into source members (create srcfile & member if required).
// 2. Compile source into objects.
// 3. Send installation progress user messages.
// 4. Execute qcmdexc as required.
// 5. Execute SQL statements as required.
//
// This program is free software, you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation.  See GNU General Public License for details
//---------------------------------------------------------------------------------------
// >>PRE-COMPILER<<
//   >>CRTCMD<< CRTBNDRPG    PGM(&LI/&OB) SRCFILE(&SL/&SF) SRCMBR(*PGM) +
//                           DBGVIEW(*LIST) OPTION(*EVENTF);
//   >>EXECUTE<<
// >>END-PRE-COMPILER<<
//---------------------------------------------------------------------------------------
ctl-opt dftactgrp(*no) actgrp(*caller) bnddir('QC2LE');
//---------------------------------------------------------------------------------------
dcl-f xmlinput disk(112) usropn; // uploaded text
dcl-f qxxxsrc disk(112) usage(*output) usropn; // parsed out
//--------------------------------------------------------------------
dcl-pi *n;
  ParseSrcMbr  char(10); // source member
  ParseSrcFile char(10); // source file
  ParseSrcLib  char(10); // source lib
  //  optional parameters:
  i_OvrSrcFile char(10) options(*nopass); // override to src
  i_Conditions char(128) options(*nopass); // pre-def conditions
  i_TgtRls     char(10) options(*nopass); // target release
end-pi;
//--------------------------------------------------------------------
// create parm prototypes
//--------------------------------------------------------------------
//  Tokenize String
dcl-pr strtok pointer extproc('strtok');
  i_string pointer options(*string) value;
  i_token  pointer options(*string) value;
end-pr;
// retrieve member description
dcl-pr qusrmbrd extpgm('QUSRMBRD'); // MEMBER DESCRIPTION
  o_rcvVar    char(32767) options(*varsize); // RECEIVER
  i_lenRcvVar int(10) const; // LENGTH OF RECVR
  i_format    char(8) const; // UPLOAD TYPE
  i_qFile     char(20) const; // FILE   LIB
  i_mbr       char(10) const; // MEMBER NAME
  i_ovverride char(1) const; // PROCESS OVERIDE
  io_errCode  char(32767) options(*varsize); // ERROR CODE
end-pr;
// retrieve object description
dcl-pr QUSROBJD extpgm('QUSROBJD');
  o_rcvVar    char(65535) options(*varsize);
  i_lenRcvVar int(10) const;
  i_format    char(8) const;
  i_qObj      char(20) const;
  i_type      char(10) const;
  io_errCode  char(65535) options(*nopass: *varsize); // | OptGrp 1
end-pr;
// send program message
dcl-pr qmhsndpm extpgm('QMHSNDPM'); // SEND MESSAGES
  i_msgID      char(7) const; // ID
  i_qMsgF      char(20) const; // FILE
  i_msgText    char(32767) options(*varsize) const; // TEXT
  i_lenMsgText int(10) const; // LENGTH
  i_msgType    char(10) const; // TYPE
  i_callStackE char(10) const; // STACK ENTRY
  i_callStackC int(10) const; // STACK COUNTER
  i_msgKey     char(4) const; // KEY
  io_errCode   char(32767) options(*varsize); // ERROR CODE
end-pr;
// execute cl command
dcl-pr qcmdexc extpgm('QCMDEXC');
  i_cmd    char(50) const;
  i_lenCmd packed(15: 5) const;
end-pr;
//  Allocate Environment Handle
dcl-pr SQLAllocEnv like(SQLRETURN_t) extproc('SQLAllocEnv');
  o_phenv pointer value;
end-pr;
//  Allocate Connection Handle
dcl-pr SQLAllocConnect like(SQLRETURN_t) extproc('SQLAllocConnect');
  i_henv  like(SQLHENV_t) value;
  o_phdbc pointer value;
end-pr;
//  Connect to a Data Source
dcl-pr SQLConnect like(SQLRETURN_t) extproc('SQLConnect');
  i_hdbc      like(SQLHDBC_t) value;
  i_szDSN     pointer options(*string) value;
  i_cbDSN     like(SQLSMALLINT_t) value;
  i_szUID     pointer options(*string) value;
  i_cbUID     like(SQLSMALLINT_t) value;
  i_szAuthStr pointer options(*string) value;
  i_cbAuthStr like(SQLSMALLINT_t) value;
end-pr;
//  Set Connection Option
dcl-pr SQLSetConnectOption like(SQLRETURN_t) extproc('SQLSetConnectOption');
  i_hdbc    like(SQLHDBC_t) value;
  i_fOption like(SQLSMALLINT_t) value;
  i_vParam  like(SQLPOINTER_t) value;
end-pr;
//  Allocate a Statement Handle
dcl-pr SQLAllocStmt like(SQLRETURN_t) extproc('SQLAllocStmt');
  i_hdbc   like(SQLHDBC_t) value;
  o_phstmt pointer value;
end-pr;
//  Execute a Statement Directly
dcl-pr SQLExecDirect like(SQLRETURN_t) extproc('SQLExecDirect');
  i_hstmt    like(SQLHSTMT_t) value;
  i_szSqlStr pointer options(*string) value;
  i_cbSqlStr like(SQLINTEGER_t) value;
end-pr;
//  Free (or Reset) a Statement Handle
dcl-pr SQLFreeStmt like(SQLRETURN_t) extproc('SQLFreeStmt');
  i_hstmt   like(SQLHSTMT_t) value;
  i_fOption like(SQLSMALLINT_t) value;
end-pr;
//  Disconnect from a Data Source
dcl-pr SQLDisconnect like(SQLRETURN_t) extproc('SQLDisconnect');
  i_hdbc like(SQLHDBC_t) value;
end-pr;
//  Free Connection Handle
dcl-pr SQLFreeConnect like(SQLRETURN_t) extproc('SQLFreeConnect');
  i_hdbc like(SQLHDBC_t) value;
end-pr;
//  Free Environment Handle
dcl-pr SQLFreeEnv like(SQLRETURN_t) extproc('SQLFreeEnv');
  i_henv like(SQLHENV_t) value;
end-pr;
//--------------------------------------------------------------------
dcl-s long_t int(10) based(pDummy);
dcl-s short_t int(5) based(pDummy);

dcl-s SQLINTEGER_t like(long_t) based(pDummy);
dcl-s SQLSMALLINT_t like(short_t) based(pDummy);

dcl-s PTR_t pointer based(pDummy);
dcl-s SQLPOINTER_t like(PTR_t) based(pDummy);
dcl-s HENV_t like(long_t) based(pDummy);
dcl-s HDBC_t like(long_t) based(pDummy);
dcl-s HSTMT_t like(long_t) based(pDummy);
dcl-s RETCODE_t like(SQLINTEGER_t) based(pDummy);

dcl-s SQLHENV_t like(HENV_t) based(pDummy);
dcl-s SQLHDBC_t like(HDBC_t) based(pDummy);
dcl-s SQLHSTMT_t like(HSTMT_t) based(pDummy);
dcl-s SQLRETURN_t like(RETCODE_t) based(pDummy);

dcl-s retCode like(SQLRETURN_t) inz;
dcl-s hdbc like(SQLHDBC_t) inz;
dcl-s hstmt like(SQLHSTMT_t) inz;
dcl-s henv like(SQLHENV_t) inz;
dcl-s sqlInit char(1) inz(*off);
dcl-s cOptVal int(10) inz;

dcl-c SQL_NTS -3;
dcl-c SQL_COMMIT_NONE 1;
dcl-c SQL_ATTR_COMMIT 0;
dcl-c SQL_DROP 1;
//--------------------------------------------------------------------
// Read element
//--------------------------------------------------------------------
dcl-pr readElement like(bldexc);
  i_element varchar(9) value;
end-pr;
//--------------------------------------------------------------------
// Define function prototype to double quotes in a string
//--------------------------------------------------------------------
dcl-pr dblQuotes varchar(2048);
  i_string varchar(2048) value;
end-pr;
//--------------------------------------------------------------------
// Define function prototype to get attribute data from a string
//--------------------------------------------------------------------
dcl-pr getAttrData varchar(2000); // like(string_t)
  i_attr    char(10) value;
  i_string  varchar(2000) value; // like(string_t)
  i_default varchar(2000) value; // like(string_t)
end-pr;
//--------------------------------------------------------------------
// Define function prototype to check for a condition
//--------------------------------------------------------------------
dcl-pr isCondition ind;
  i_condList char(2000) value;
end-pr;
//---------------------------------------------------------------------------------------
dcl-pr loadConditions like(condition) dim(32);
  i_conditions char(128) value;
end-pr;
//--------------------------------------------------------------------
dcl-pr getCurrentRelease char(10) end-pr;
//--------------------------------------------------------------------
dcl-pr isRelease ind;
  i_os_release char(6) value;
  i_release    char(10) value;
end-pr;
//--------------------------------------------------------------------
dcl-pr setTargetRelease varchar(2000);
  i_keyword varchar(10) value;
  i_string  varchar(2000) value;
  i_value   varchar(10) value;
end-pr;
//--------------------------------------------------------------------
dcl-pr setVariable;
  i_fldName varchar(10) value;
  i_value   varchar(64) value;
end-pr;
//---------------------------------------------------------------------------------------------
dcl-pr getVarName varchar(11);
  i_bldexc like(bldexc) value;
  i_pos    int(10) value;
end-pr;
//---------------------------------------------------------------------------------------------
dcl-pr getVarValue varchar(64);
  i_name varchar(11) value;
end-pr;
//---------------------------------------------------------------------------------------------
dcl-pr uCase varchar(2000);
  i_string varchar(2000) value;
end-pr;
//--------------------------------------------------------------------
dcl-s vrcvar char(145);
dcl-s qm_msgid char(7);
dcl-s qm_msgtxt char(500);
dcl-s qm_msgq char(10);
dcl-s qm_msgtyp char(10);
dcl-s mbrname char(10);
dcl-s mbrtype char(10);
dcl-s mbrtext char(50);
dcl-s srcfile char(10);
dcl-s srclen char(5);
dcl-s srccssid char(5);
dcl-s bldexc char(2000);
dcl-s write_flag ind inz(*off);
dcl-s srcSeqno zoned(6: 2) inz(0);
dcl-s aa uns(5) inz(0);
dcl-s ll uns(5) inz(0);
dcl-c qs '''';
dcl-c qd '"';
dcl-s errFLag char(1) inz(*off);
dcl-s cnd_msg char(42);
dcl-s cnd_values char(110);
dcl-s cnd_var char(10);
dcl-s cnd_rtnVal char(10);
dcl-s cnd_array like(condition) dim(32) inz;
dcl-s cnd_ptr int(10) inz;
dcl-s condition char(10);
dcl-s condList char(2000);
dcl-s release char(10);
dcl-s dltsplf char(10);
dcl-s objd_obj char(10);
dcl-s objd_lib char(10);
dcl-s objd_objtype char(10);
dcl-s objd_rtnlib char(10);
dcl-ds objd0100;
  od_bytRet int(10) pos(1);
  od_bytAvl int(10) pos(5);
  od_name   char(10) pos(9);
  od_lib    char(10) pos(19);
  od_type   char(10) pos(29);
  od_rtnLib char(10) pos(39);
end-ds;
dcl-ds fld_array;
  fld_x     int(10) inz;
  fld_name  varchar(11) inz dim(64);
  fld_value varchar(64) inz dim(64);
end-ds;
dcl-s var_name varchar(11) inz;
dcl-s var_value varchar(64) inz;
// Error return code parm for APIs.
dcl-ds errCode;
  errCode_bytPrv   int(10) inz(%size(errCode));
  errCode_bytAvl   int(10) inz(0);
  errCode_excID    char(7) inz;
  errCode_reserved char(1) inz;
  errCode_escData  char(256) inz;
end-ds;
// Optional parameters
dcl-s OvrSrcFile like(i_OvrSrcFile) inz;
dcl-s isPreDefCond ind inz(*off);
dcl-s TgtRls like(i_TgtRls) inz;

// Program status data structure.
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
//--------------------------------------------------------------------
dcl-ds xmlRecord len(112); // record of xmlinput
  xmltag1 char(9) pos(13);
  xmltag2 char(10) pos(18);
  xmlcode char(100) pos(13);
end-ds;
dcl-ds srcRecord len(112) qualified; // record of qxxxsrc
  srcSeq zoned(6: 2) pos(1);
  srcDat char(6) pos(7);
  srcDta char(100) pos(13);
end-ds;
//--------------------------------------------------------------------

//  get optional parameter: Overrride to Source File
if (%parms() >= 4);
  OvrSrcFile = i_OvrSrcFile;
else;
  OvrSrcFile = '';
endif;

//  get optional parameter: Conditions
if (%parms() >= 5);
  if (%subst(i_Conditions:1:32) <> '');
    cnd_array = loadConditions(i_Conditions);
    isPreDefCond = *on;
  else;
    isPreDefCond = *off;
  endif;
endif;

//  get optional parameter: Target Release
if (%parms() >= 6);
  TgtRls = i_TgtRls;
else;
  TgtRls = getCurrentRelease();
endif;

exsr srValidate;  // make sure exist

// Set user selected library *first for remainder of program
bldexc = 'RMVLIBLE LIB('+
  %trimr(ParseSrcLib) + ')';
callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));

bldexc = 'ADDLIBLE LIB('+
  %trimr(ParseSrcLib) + ') POSITION(*FIRST)';
callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));

//       CPF2103 - Library &1 already exists in library list.
if (%error and sds_msgID <> 'CPF2103');
  qm_msgtxt = '0000 ' + sds_msgText;
  exsr srKill;
endif;

// Set variable &TOLIB
setVariable('tolib': ParseSrcLib);

// Set variable &TGTRLS
setVariable('tgtrls': TgtRls);

// Set variable &XMLFILE
setVariable('xmlfile': ParseSrcFile);

// Set variable &XMLLIB
setVariable('xmllib': ParseSrcFile);

// Set variable &XMLMBR
setVariable('xmlmbr': ParseSrcFile);

// Override Input file to uploaded text file
bldexc = 'OVRDBF FILE(XMLINPUT) TOFILE(' +
  %trimr(ParseSrcLib)+'/'+
  %trimr(ParseSrcFile) + ') MBR(' +
  %trimr(ParseSrcMbr) + ')';
qcmdexc(bldexc:%len(%trimr(bldexc)));
open xmlinput;
read xmlinput xmlRecord;
dow (not %eof);
  // write records to outfile if flag is on
  select;
  when (write_flag = *on);
    if (xmltag2<>'</copysrc>');
      srcSeqno=srcSeqno+1;
      srcRecord.srcSeq = srcSeqno;
      srcRecord.srcDat = '000000';
      srcRecord.srcDta = xmlcode;
      write qxxxsrc srcRecord;
    else;
      write_flag=*off;
      close qxxxsrc;
    endif;

  // Extract values based on xml tags.
  when (xmltag1 = 'mbrname =');
    mbrname = %subst(xmlcode:13:10);
  when (xmltag1 = 'mbrtype =');
    mbrtype =%subst(xmlcode:13:10);
  when (xmltag1 = 'mbrtext =');
    mbrtext =dblQuotes(%subst(xmlcode:13:50));
  when (xmltag1 = 'srcfile =');
    if (OvrSrcFile <> '');
      srcfile =OvrSrcFile;
    else;
      srcfile =%subst(xmlcode:13:10);
    endif;
  when (xmltag1 = 'srclen  =');
    srclen  =%subst(xmlcode:13:5);
  when (xmltag1 = 'srccssid=');
    srccssid=%subst(xmlcode:13:5);
  //--------------------------------------------------------------------
  // Start of data to copy.  Create source files/mbrs as required.
  //--------------------------------------------------------------------
  when (xmltag1='<copysrc>');
    // crtsrcpf
    bldexc = 'CRTSRCPF FILE(' +
      %trimr(ParseSrcLib)+'/'+
      %trimr(srcfile) + ') RCDLEN(' +
      srclen + ') CCSID(' +
      srccssid + ')';
    callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));
    // addpfm
    bldexc = 'ADDPFM   FILE(' +
      %trimr(ParseSrcLib)+'/'+
      %trimr(srcfile) + ') MBR(' +
      %trimr(mbrname) + ') SRCTYPE(' +
      %trimr(mbrtype) + ') TEXT(' +
      qs+%trimr(mbrtext)+qs + ')';
    callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));
    if (%error);
      // chgpfm
      bldexc = 'CHGPFM   FILE(' +
        %trimr(ParseSrcLib)+'/'+
        %trimr(srcfile) + ') MBR(' +
        %trimr(mbrname) + ') TEXT(' +
        qs+%trimr(mbrtext)+qs + ')';
      qcmdexc(bldexc:%len(%trimr(bldexc)));
      // clr mbr
      bldexc = 'CLRPFM   FILE(' +
        %trimr(ParseSrcLib)+'/'+
        %trimr(srcfile) + ') MBR(' +
        %trimr(mbrname) + ')';
      qcmdexc(bldexc:%len(%trimr(bldexc)));
    endif;
    // ovr to outfile mbr
    bldexc = 'OVRDBF QXXXSRC ' +
      %trimr(ParseSrcLib) + '/' +
      %trimr(srcfile) + ' ' +
      mbrname;
    qcmdexc(bldexc:%len(%trimr(bldexc)));
    clear srcSeqno;
    open qxxxsrc;
    write_flag = *on;
  //--------------------------------------------------------------------
  // Compile statement.  Read next record and execute it.
  //--------------------------------------------------------------------
  when (xmltag1 = '<compile ');
    condList= getAttrData('condition':xmlcode:'');
    read xmlinput xmlRecord;
    bldexc = readElement('compile');
    if (isCondition(condList));
      exsr RplVars;
      exsr SetTgtRls;
      qcmdexc(bldexc:%len(%trimr(bldexc)));
    endif;
  //--------------------------------------------------------------------
  // qcmdexc statement. Build statement from each record between start
  // and stop tags.  When stop tag is found, execute statement.
  //--------------------------------------------------------------------
  when (xmltag1 = '<qcmdexc ');
    condList = getAttrData('condition'
                           :xmlcode:'');
    release  = getAttrData('release'
                           :xmlcode:'*CURRENT');
    dltsplf  = getAttrData('dltsplf'
                           :xmlcode:'*NONE');
    read xmlinput xmlRecord;
    bldexc = readElement('qcmdexc');
    if (isCondition(condList) and
        isRelease(tgtRls: release));
      exsr RplVars;
      exsr SetTgtRls;
      if (%subst(bldexc: 1: 3) = 'DLT');
        callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));
      else;
        callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));
        if (%error());
          qm_msgtxt = '0000 Failed to execute: '+bldexc;
          exsr srKill;
        endif;
        if (dltsplf <> '' and dltsplf <> '*NONE');
          bldexc = 'DLTSPLF FILE(' + dltsplf +
                   ') JOB(*) SPLNBR(*LAST)';
          callp(e) qcmdexc(bldexc:%len(%trimr(bldexc)));
        endif;
      endif;
    endif;
  //--------------------------------------------------------------------
  // SQL statement. Build statement from each record between start
  // and stop tags.  When stop tag is found, execute SQL statement.
  //--------------------------------------------------------------------
  when (xmltag1 = '<execsql ');
    condList = getAttrData('condition'
                           :xmlcode:'');
    read xmlinput xmlRecord;
    bldexc = readElement('execsql');
    if (isCondition(condList));
      exsr RplVars;
      exsr srSQLExecute;
    endif;
  //--------------------------------------------------------------------
  // Send messages to user as program executes
  // Extract message ID, Message Type, from <sendmsg>
  // read a record and get the single line of message text.
  //--------------------------------------------------------------------
  when (xmltag1 = '<sendmsg ');
    qm_msgid = %subst(xmlcode:22:7);
    qm_msgtyp = %subst(xmlcode:46:10);
    read xmlinput xmlRecord;
    qm_msgq   = '*EXT   ';
    qm_msgtxt = xmlcode;
    exsr srSndMessage;
  //--------------------------------------------------------------------
  // rtvobjd statement. retrieve object description of the specified
  // object. Store attributes in specified fields.
  //--------------------------------------------------------------------
  when (xmltag1 = '<rtvobjd ');
    condList = getAttrData('condition'
                           :xmlcode:'');
    bldexc = readElement('rtvobjd');
    objd_obj    =getAttrData('obj'    :bldexc:'');
    objd_lib    =getAttrData('lib'    :bldexc:'');
    objd_objtype=getAttrData('objtype':bldexc:'');
    objd_rtnlib =getAttrData('rtnlib' :bldexc:'');
    if (isCondition(condList));
      exsr srRtvObjD;
    endif;
  //--------------------------------------------------------------------
  // chgvar statement.
  //--------------------------------------------------------------------
  when (xmltag1 = '<chgvar  ');
    condList = getAttrData('condition'
                           :xmlcode:'');
    bldexc = readElement('chgvar');
    var_name  = getAttrData('var'    :bldexc:'');
    var_value = getAttrData('value'  :bldexc:'');
    if (isCondition(condList));
      exsr srChgVar;
    endif;
  //--------------------------------------------------------------------
  // Query condition
  //--------------------------------------------------------------------
  when (xmltag1 = '<qrycond ');
    bldexc = readElement('qrycond');
    cnd_msg = getAttrData('msg'   : bldexc: '');
    cnd_values = getAttrData('values': bldexc:'');
    cnd_var = getAttrData('var': bldexc: '*NONE');
    exsr srQueryCond;
  endsl;

  read xmlinput xmlRecord;
enddo;

exsr srSQLEnd;
*inlr=*on;
return;
//--------------------------------------------------------------------
// Replace variable names with their associated values.
//--------------------------------------------------------------------
begsr RplVars;
  aa=%scan('&':bldexc);
  dow (aa>0);
    var_name=getVarName(bldexc:aa);
    var_value=getVarValue(var_name);
    bldexc=%replace(var_value:bldexc:aa
                    :%len(var_name));
    aa=%scan('&':bldexc);
  enddo;
endsr;
//--------------------------------------------------------------------
// Sets the target release according to the optional parameter
// i_TgtRls.
//--------------------------------------------------------------------
begsr SetTgtRls;
  if (TgtRls = getCurrentRelease());
    leavesr;
  endif;
  bldexc =
     setTargetRelease('TGTRLS': bldexc: TgtRls);
endsr;
//--------------------------------------------------------------------
// Check of file, lib, member exist.
//--------------------------------------------------------------------
begsr srValidate;
  QUSRMBRD(
    vrcvar:
    145:
    'MBRD0100':
    ParseSrcFile + ParseSrcLib:
    ParseSrcMbr:
    '0':
    errCode);
  //   --------------------------------------------------------------------------------
  //   If error occurred on call, send appropriate message back to user.
  //   ---------------------------------------------------------------------------------
  if (errCode_bytAvl <> 0);  // error occurred
    select;
    // lib not found
    when (errCode_excID = 'CPF9810');
      qm_msgtxt = '0000 Library ' +
        %trimr(ParseSrcLib) + ' was not found.';
    // src file not found
    when (errCode_excID = 'CPF9812');
      qm_msgtxt = '0000 Source file ' +
        %trimr(ParseSrcFile)+' was not found in ' +
        %trimr(ParseSrcLib) + '.';
    // member not found
    when (errCode_excID = 'CPF9815');
      qm_msgtxt = '0000 Member ' +
        %trimr(ParseSrcMbr)+' was not found in ' +
        %trimr(ParseSrcLib)+'/'+ %trimr(ParseSrcFile);
    // unexpected
    other;
      qm_msgtxt = '0000 Unexpected message ' +
        errCode_excID + ' received. ';
    endsl;
    // send message
    exsr srKill;
    *inlr=*on;
    return;
  endif;
endsr;
//--------------------------------------------------------------------
// kill application
//--------------------------------------------------------------------
begsr srKill;
  qm_msgid  = 'CPD0006';
  qm_msgtyp = '*DIAG';
  qm_msgq   = '*CTLBDY';
  exsr srSndMessage;
  qm_msgtxt = *blanks;
  qm_msgid  = 'CPF0002';
  qm_msgtyp = '*ESCAPE';
  exsr srSndMessage;
endsr;
//--------------------------------------------------------------------
// call send program message api
//--------------------------------------------------------------------
begsr srSndMessage;
  QMHSNDPM(
    qm_msgid:
    'QCPFMSG   *LIBL     ':
    qm_msgtxt:
    %size(qm_msgtxt):
    qm_msgtyp:
    qm_msgq:
    1:
    '    ':
    errCode);
endsr;
//--------------------------------------------------------------------
// retrieve object description and store attributes
//--------------------------------------------------------------------
begsr srRtvObjD;
  QUSROBJD(objd0100
           : %size(objd0100)
           : 'OBJD0100'
           : objd_obj + objd_lib
           : objd_objtype
           : errCode);
  if (errCode_bytAvl <> 0);  // error occurred
    qm_msgtxt = '0000 Failed to retrieve +
      object description of object ' +
      %trim(objd_lib) + '/' + %trim(objd_obj) +
      ' type ' + %trim(objd_objtype) + '.';
    // send message
    exsr srKill;
  else;
    setVariable(objd_rtnlib: od_rtnlib);
  endif;
endsr;
//--------------------------------------------------------------------
// change variable
//--------------------------------------------------------------------
begsr srChgVar;
  setVariable(var_name: var_value);
endsr;
//--------------------------------------------------------------------
// execute SQL statement.
//--------------------------------------------------------------------
begsr srSQLExecute;
  exsr srSQLInit;
  retCode = SQLExecDirect(hstmt    :
                          bldexc   :
                          SQL_NTS  );
endsr;
//--------------------------------------------------------------------
// query condition.
//--------------------------------------------------------------------
begsr srQueryCond;
  if (isPreDefCond = *off);
    cnd_values = uCase(cnd_values);
    dou ((%scan(cnd_rtnVal: cnd_values) > 0) and
         (cnd_rtnval <> ''                 ));
      cnd_rtnval = ' ';
      dsply cnd_msg '' cnd_rtnval;
      cnd_rtnVal = uCase(cnd_rtnVal);
    enddo;
    cnd_ptr = cnd_ptr + 1;
    cnd_array(cnd_ptr) = cnd_rtnVal;
  endif;
  if (cnd_var <> '*NONE');
    setVariable(cnd_var: cnd_rtnval);
  endif;
endsr;
//--------------------------------------------------------------------
// initialize SQL.
//--------------------------------------------------------------------
begsr srSQLInit;

  if (sqlInit = *off);
    retCode = SQLAllocEnv(%addr(henv));
    retCode = SQLAllocConnect(henv: %addr(hdbc));
    retCode = SQLConnect(hdbc      :
                         '*LOCAL'  :
                         SQL_NTS   :
                         *null     :
                         SQL_NTS   :
                         *null     :
                         SQL_NTS   );
    cOptVal = SQL_COMMIT_NONE;
    retCode = SQLSetConnectOption(hdbc          :
                                 SQL_ATTR_COMMIT:
                                 %addr(cOptVal) );
    retCode = SQLAllocStmt(hdbc       :
                         %addr(hstmt) );
    sqlInit = *on;
  endif;
endsr;
//--------------------------------------------------------------------
// end SQL.
//--------------------------------------------------------------------
begsr srSQLEnd;
  if (sqlInit = *on);
    retCode = SQLFreeStmt(hstmt    :
                          SQL_DROP );
    retCode = SQLDisconnect(hdbc);
    retCode = SQLFreeConnect(hdbc);
    retCode = SQLFreeEnv(henv);
    sqlInit = *off;
  endif;
endsr;
//--------------------------------------------------------------------
// error handler
//--------------------------------------------------------------------
begsr *pssr;
  if (errFLag = *off);
    errFlag = *on;
    exsr srSQLEnd;
  endif;
endsr '*CANCL';
//--------------------------------------------------------------------
// Read element
//--------------------------------------------------------------------
dcl-proc readElement;
  dcl-pi *n like(bldexc);
    i_element varchar(9) value;
  end-pi;

  dcl-s i int(10) inz;
  dcl-s value like(bldexc) inz;
  dcl-s endTag like(xmlTag2) inz;

  i = 1;
  endTag = '</' + i_element + '>';
  dow (xmltag2 <> endTag);
    %subst(value: i: %len(xmlcode)) = xmlcode;
    i = i + %len(xmlcode);
    read xmlinput xmlRecord;
  enddo;

  return value;

end-proc;
//--------------------------------------------------------------------
// Double quotes
//--------------------------------------------------------------------
dcl-proc dblQuotes;
  dcl-pi *n varchar(2048);
    i_string varchar(2048) value;
  end-pi;

  dcl-s x int(10) inz;
  dcl-s string varchar(2048) inz;

  for x = 1 to %len(i_string);
    string = string + %subst(i_string: x:1);
    if (%subst(i_string: x : 1) = qs);
      string = string + qs;
    endif;
  endfor;

  return string;

end-proc;
//---------------------------------------------------------------------------------------------
//  Get Attribute Data from String
//---------------------------------------------------------------------------------------------
dcl-proc getAttrData;
  dcl-pi *n varchar(2000); // like(string_t)
    i_attr    char(10) value;
    i_string  varchar(2000) value; // like(string_t)
    i_default varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s attrData varchar(2000) inz; // like(string_t)

  //  local fields
  dcl-s attr varchar(20) inz;
  dcl-s lenAttr int(10) inz;
  dcl-s aa int(10) inz;
  dcl-s cc int(10) inz;

  dcl-c Qd '"';
  //-------------------------------------------------------------------*

  //  find the keyword
  attr = %trim(i_attr) + '=' + Qd;

  aa   = %scan(attr: i_string);
  if (aa = 0);
    return i_default;
  endif;

  aa   = aa + %len(attr);
  cc   = %scan(Qd: i_string: aa+1);

  //  return the data between the double-quotes
  if ((cc-aa) > 0);
    attrData = %subst(i_string: aa: cc-aa);
  endif;

  return attrData;

end-proc;
//---------------------------------------------------------------------------------------------
//  Load condition array
//---------------------------------------------------------------------------------------------
dcl-proc loadConditions;
  dcl-pi *n like(condition) dim(32);
    i_conditions char(128) value;
  end-pi;

  //  return value
  dcl-s cnd_array like(condition) dim(32) inz;
  dcl-s pValue pointer inz;
  dcl-s x int(10) inz;
  dcl-s i int(10) inz;
  dcl-s cnd_value varchar(128);
  dcl-s var_name varchar(64);
  dcl-s var_value varchar(64);
  //-------------------------------------------------------------------*

  i_conditions = uCase(i_conditions);

  pValue = strtok(i_conditions: ';');
  dow (pValue <> *null);
    x = x + 1;
    cnd_value = %str(pValue);
    i = %scan('=': cnd_value);
    if (i = 0);
      cnd_array(x) = cnd_value;
    else;
      var_name = %subst(cnd_value: 1: i-1);
      if (%subst(var_name: 1: 1) = '&');
        var_name = %subst(var_name: 2);
      endif;
      var_value = %subst(cnd_value: i+1);
      setVariable(var_name: var_value);
      cnd_array(x) = var_value;
    endif;
    pValue = strtok(*null: ';');
  enddo;

  return cnd_array;
end-proc;
//---------------------------------------------------------------------------------------------
//  Check for a condition
//---------------------------------------------------------------------------------------------
dcl-proc isCondition;
  dcl-pi *n ind;
    i_condList char(2000) value;
  end-pi;

  //  return value
  dcl-s isCondition ind inz;
  dcl-s pValue pointer inz;
  dcl-s aCondition char(10) inz;
  //-------------------------------------------------------------------*

  i_condList = uCase(i_condList);

  if ((i_condList = '*NONE')  or
      (i_condList = ''     ));
    *in01 = *on;
  else;

    pValue = strtok(i_condList: ' ');
    dow (pValue <> *null);
      aCondition = %str(pValue);
      *in01 = %lookup(aCondition: cnd_array) > 0;
      if (not *in01);
        leave;
      endif;
      pValue = strtok(*null     : ' ');
    enddo;

  endif;

  if (*in01);
    isCondition = *on;
  else;
    isCondition = *off;
  endif;

  return isCondition;
end-proc;
//---------------------------------------------------------------------------------------------
//  Get the current release level of the operation system
//---------------------------------------------------------------------------------------------
dcl-proc getCurrentRelease;
  dcl-pi *n char(10) end-pi;

  //  QSZRTVPR API
  dcl-pr QSZRTVPR extpgm('QSZRTVPR');
    o_rcvVar    char(65535) options(*varsize);
    i_lenRcvVar int(10) const;
    i_format    char(8) const;
    o_prodInf   char(65535) options(*varsize) const;
    io_errCode  char(65535) options(*varsize);
  end-pr;

  dcl-ds prdi0100 qualified;
    productID  char(7) pos(1) inz('*OPSYS');
    releaseLvl char(6) pos(8) inz('*CUR');
    productOpt char(4) pos(14) inz('0000');
    loadID     char(10) pos(18) inz('*CODE');
  end-ds;
  //  Shortened!:
  dcl-ds prdr0100 qualified;
    bytRet     int(10) pos(1);
    bytAvl     int(10) pos(5);
    reserved_1 int(10) pos(9);
    productID  char(7) pos(13);
    releaseLvl char(6) pos(20);
  end-ds;
  //  API error code
  dcl-ds errCode;
    bytPrv int(10) inz(0);
    bytAvl int(10) inz(0);
  end-ds;
  //-------------------------------------------------------------------*

  QSZRTVPR(prdr0100: %size(prdr0100):
           'PRDR0100': prdi0100: errCode);
  return prdr0100.releaseLvl;

end-proc;
//---------------------------------------------------------------------------------------------
//  Check the release level
//---------------------------------------------------------------------------------------------
dcl-proc isRelease;
  dcl-pi *n ind;
    i_os_release char(6) value;
    i_release    char(10) value;
  end-pi;

  //  return value
  dcl-s isRelease ind inz(*off);
  //  Release
  dcl-ds release;
    r_operator char(3) pos(1);
    r_space    char(1) pos(4);
    r_level    char(6) pos(5);
  end-ds;
  //-------------------------------------------------------------------*

  if (i_release = '*CURRENT');
    isRelease = *on;
  else;
    release = i_release;
    select;
    when (r_operator = '*LT' and
          i_os_release < r_level);
      isRelease = *on;
    when (r_operator = '*EQ' and
          i_os_release = r_level);
      isRelease = *on;
    when (r_operator = '*GT' and
          i_os_release > r_level);
      isRelease = *on;
    when (r_operator = '*LE' and
          i_os_release <= r_level);
      isRelease = *on;
    when (r_operator = '*GE' and
          i_os_release >= r_level);
      isRelease = *on;
    other;
      isRelease = *off;
    endsl;
  endif;

  return isRelease;

end-proc;
//---------------------------------------------------------------------------------------------
//  Replaces the value of a given keyword.
//---------------------------------------------------------------------------------------------
dcl-proc setTargetRelease;
  dcl-pi *n varchar(2000);
    i_keyword varchar(10) value;
    i_string  varchar(2000) value;
    i_value   varchar(10) value;
  end-pi;

  //  return value
  dcl-s string varchar(2000) inz;

  //  helper fields
  dcl-s x int(10) inz;
  dcl-s l int(10) inz;
  dcl-s tmpKeyword like(i_keyword) inz;
  dcl-s tmpString like(i_string) inz;
  dcl-s tmpCmd char(10) inz;
  //-------------------------------------------------------------------*

  tmpKeyword = uCase(%trimr(i_keyword));
  tmpString  = uCase(%trimr(i_string ));
  x = %scan(' ': tmpString);
  if (x = 0);
    return i_string;
  endif;
  tmpCmd = %subst(tmpString: 1: x);
  if (tmpCmd <> 'CRTRPGMOD' and
      tmpCmd <> 'CRTRPGPGM' and
      tmpCmd <> 'CRTCLMOD'  and
      tmpCmd <> 'CRTCLPGM'  and
      tmpCmd <> 'CRTCBLMOD' and
      tmpCmd <> 'CRTCBLPGM' and
      tmpCmd <> 'CRTCMOD'   and
      tmpCmd <> 'CRTCPPMOD' and
      tmpCmd <> 'CRTBNDC'   and
      tmpCmd <> 'CRTBNDCBL' and
      tmpCmd <> 'CRTBNDCL'  and
      tmpCmd <> 'CRTBNDCPP' and
      tmpCmd <> 'CRTBNDDIR' and
      tmpCmd <> 'CRTBNDRPG' and
      tmpCmd <> 'CRTPGM'    and
      tmpCmd <> 'CRTSRVPGM') ;
    return i_string;
  endif;
  x = %scan(tmpKeyword + '(': tmpString);
  if (x = 0);
    return %trimr(i_string) +
           ' ' + tmpKeyword + '(' + %trimr(i_value) + ')';
  endif;
  l = %scan(')': tmpString: x + %len(i_keyword) + 1);
  if (l = 0);
    return i_string;
  endif;
  l = l - x + 1;
  string = %replace(tmpKeyword + '(' + %trimr(i_value) + ')'
                    : i_string: x: l);
  return string;

end-proc;
//---------------------------------------------------------------------------------------------
//  Store field value.
//---------------------------------------------------------------------------------------------
dcl-proc setVariable;
  dcl-pi *n;
    i_fldName varchar(10) value;
    i_value   varchar(64) value;
  end-pi;
  dcl-s i int(10) inz;
  //-------------------------------------------------------------------*

  if (i_fldName = '');
    return;
  endif;

  for i = 1 to fld_x;
    if (uCase('&' + %trim(i_fldName)) = uCase(fld_name(i)));
      fld_value(i) = i_value;
      return;
    endif;
  endfor;

  if (fld_x >= %elem(fld_name));
    return;
  endif;

  fld_x = fld_x + 1;
  fld_name(fld_x)  = uCase('&' + %trim(i_fldName));
  fld_value(fld_x) = i_value;

end-proc;
//---------------------------------------------------------------------------------------------
//  get variable name from statement.
//---------------------------------------------------------------------------------------------
dcl-proc getVarName;
  dcl-pi *n varchar(11);
    i_bldexc like(bldexc) value;
    i_pos    int(10) value;
  end-pi;
  dcl-s name varchar(11) inz;
  dcl-c CHARS '&ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456+
    7890_';
  //-------------------------------------------------------------------*

  dow (i_pos<=%len(i_bldexc) and
       %check(CHARS:%subst(i_bldexc:i_pos:1))=0);
    name = name+%subst(i_bldexc:i_pos:1);
    i_pos=i_pos+1;
  enddo;

  return name;

end-proc;
//---------------------------------------------------------------------------------------------
//  get variable value.
//---------------------------------------------------------------------------------------------
dcl-proc getVarValue;
  dcl-pi *n varchar(64);
    i_name varchar(11) value;
  end-pi;
  dcl-s i int(10) inz;
  dcl-s value varchar(64) inz('?');
  //-------------------------------------------------------------------*

  for i=1 to fld_x;
    if (ucase(fld_name(i))=uCase(i_name));
      value=%trimr(fld_value(i));
      leave;
    endif;
  endfor;

  return value;

end-proc;
//---------------------------------------------------------------------------------------------
//  convert to upper case
//---------------------------------------------------------------------------------------------
dcl-proc uCase;
  dcl-pi *n varchar(2000);
    i_string varchar(2000) value;
  end-pi;
  dcl-s uCase varchar(2000) inz;
  dcl-c LC 'abcdefghijklmnopqrstuvwxyz';
  dcl-c UC 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  //-------------------------------------------------------------------*

  uCase = %xlate(LC:UC:i_string);

  return uCase;

end-proc;
