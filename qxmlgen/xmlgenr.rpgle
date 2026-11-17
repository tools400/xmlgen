**free
//%METADATA                                                      *
// %TEXT gen xml source file                                     *
//%EMETADATA                                                     *
//--------------------------------------------------------------------------------------------
// XMLGENR - generate XML code for utility uploads.
// Copyright (C) 6/19/2001  Craig Rutledge    <craig_rutledge@mohawkind.com>
//
// This program is free software, you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation.  See GNU General Public License for details
//--------------------------------------------------------------------------------------------
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
//                           MODULE(&LI/&OB               +
//                                  &LI/XMLGENRS     )    +
//                           ACTGRP(*NEW) +
//                           DETAIL(*BASIC);
// >>END-PRE-COMPILER<<
//--------------------------------------------------------------------------------------------
/copy 'qxmlgen/copyright.rpgleinc'

//--------------------------------------------------------------------------------------------
// Read member script file to generate XML data
//--------------------------------------------------------------------------------------------

dcl-s ArryDTD char(100) dim(52) ctdata perrcd(1); // document template
dcl-s ArryInstruct char(100) dim(21) ctdata perrcd(1); // instructions
dcl-s ArryInstPgm char(100) dim(1177) ctdata perrcd(1); // installer source
dcl-s ba char(1) inz('['); // open bracket
dcl-s bb char(1) inz(']'); // close bracket
dcl-c Qs '''';
dcl-c Qd '"';
dcl-s aa uns(5) inz;
dcl-s vrcvar char(400);
dcl-s String varchar(2000);
dcl-s genSrcFile varchar(30);

//----------------------------------------------------------------
// command definition fields
//----------------------------------------------------------------
dcl-s vcpgm char(10); // cmd processing
dcl-s vCLIB char(10);
dcl-s vSFILE char(10); // SOURCE FILE NAM
dcl-s vSLIB char(10);
dcl-s vSMBR char(10); // SOURCE MBR
dcl-s vVPGM char(10); // VALIDITY CHECKR
dcl-s vVLIB char(10);

dcl-ds vMODE;
  vMODE_PROD    char(1) pos(1);
  vMODE_DEBUG   char(1) pos(2);
  vMODE_SERVICE char(1) pos(3);
  vMODE_Res     char(7) pos(4);
end-ds;

dcl-ds vALW len(15);
  vALW_BPGM     char(1) pos(1);
  vALW_IPGM     char(1) pos(2);
  vALW_EXEC     char(1) pos(3);
  vALW_INTERACT char(1) pos(4);
  vALW_BATCH    char(1) pos(5);
  vALW_BREXX    char(1) pos(6);
  vALW_IREXX    char(1) pos(7);
  vALW_BMOD     char(1) pos(8);
  vALW_IMOD     char(1) pos(9);
  vALW_Res      char(6) pos(10);
end-ds;

dcl-s vALWLM char(10) inz('YES ');
dcl-s vPMFIL char(10); // PROMPT OVR FILE
dcl-s vPMLIB char(10);
dcl-s vMSFIL char(10); // MESSAGE FILE
dcl-s vMSLIB char(10);
dcl-s vHLPNL char(10); // HELP PANEL GRP
dcl-s vHLIB char(10);
dcl-s vHLPID char(10); // HELP ID
dcl-s vPLIB char(10); // PRODUCT LIBRARY
dcl-s vOVPGM char(10); // OVERRIDE PROMPT
dcl-s vOVLIB char(10);
dcl-s vTEXT char(50); // TEXT

//----------------------------------------------------------------
// Error return code parm for APIs.
//----------------------------------------------------------------
dcl-ds errCode qualified;
  bytPrv     int(10) inz(%size(errCode));
  bytAvl     int(10);
  excID      char(7);
  reserved_1 char(1);
  excDta     char(256);
end-ds;

//---------------------------------------------------------------------------------------------
//  Imported procedures and functions:
//---------------------------------------------------------------------------------------------
/copy 'qxmlgen/xmlgenrs_h.rpgleinc'

// Define function prototype to remove *IMMED from BNDSRVPGM parameter
dcl-pr chgBndSrvPgmParm like(string) extproc('chgBndSrvPgmParm'); // like(string_t)
  i_command like(string) const; // like(string_t)
end-pr;

//---------------------------------------------------------------------------------------------
// Create private Prototypes
//---------------------------------------------------------------------------------------------
dcl-pr rtvCondition like(string_t) extproc('rtvCondition');
  i_string like(string_t) value;
end-pr;

//---------------------------------------------------------------------------------------------
// Create Prototypes for C functions
//---------------------------------------------------------------------------------------------
//  Tokenize String
dcl-pr strtok pointer extproc('strtok');
  i_string pointer options(*string) value;
  i_token  pointer options(*string) value;
end-pr;

//---------------------------------------------------------------------------------------------
// Create Prototypes for calls
//---------------------------------------------------------------------------------------------
dcl-pr qcdrcmdi extpgm('QCDRCMDI'); // COMMAND DEFINITIONS
  o_rcvVar    char(32767) options(*varsize); // RECEIVER
  i_lenRcvVar int(10) const; // LENGTH OF RECVR
  i_format    char(8) const; // FORM TYPE
  i_qCmd      char(20) const; // CMD   LIB
  io_errCode  char(32767) options(*varsize); // ERROR CODE
end-pr;

//---------------------------------------------------------------------------------------------
// system -- Execute a Command
//---------------------------------------------------------------------------------------------
//     Return value       Meaning
//     ----------------   --------------------------------------
//     0                  the command is successful
//     -1                 for a NULL pointer
//     1                  the command fails
dcl-pr system int(10) extproc('system');
  i_clCommand pointer options(*string) value;
end-pr;

dcl-s EXCP_MSGID char(7) import('_EXCP_MSGID');

//---------------------------------------------------------------------------------------------
// values extracted from mbr script command
dcl-s xinclude char(4); // gen compile code?
dcl-s xmbr char(10); // member name
dcl-s xmbratr char(10); // source mbr attr
dcl-s xfromsrcf char(10); // copy from src file
dcl-s xfromsrcl char(10); // copy from src lib
dcl-s xtosrcf char(10); // copy to src file
dcl-s xobjtype varchar(10) inz; // object type
dcl-s xgencrt char(4); // gen compile code?
dcl-s xparam char(200); // optional parameter
dcl-s xcondition char(200); // compile condition
dcl-s xcommand like(string_t) inz; // cl/sql command
dcl-s xParmVal like(string_t) inz; // cl/sql command
dcl-s xrelease char(10); // compile condition
dcl-s xdltsplf char(10); // compile condition
dcl-s xmsg char(52) inz; // cond. msg text
dcl-ds xvalues;
  xvalues_entry char(11) inz dim(10);
end-ds;
dcl-s values char(128) inz;
dcl-s value char(10) based(pValue);
dcl-s xcndData varchar(632) inz;
dcl-s xobj varchar(10) inz;
dcl-s xlib varchar(10) inz;
dcl-s xrtnlib varchar(11) inz;
dcl-s xvar varchar(11) inz;
dcl-s xvalue varchar(64) inz;
dcl-s xrtnvrs varchar(15) inz;
dcl-s xsrcfile varchar(10) inz;
dcl-s xsrclib varchar(10) inz;
dcl-s xsrcmbr varchar(10) inz;

dcl-s cc int(10) inz;
dcl-s xmlString varchar(2000) inz;
dcl-ds text len(50) qualified;
  version char(16) pos(35);
end-ds;
dcl-s clCommand varchar(500) inz;

dcl-s xScriptSource varchar(240) inz;
dcl-s xMbrSource varchar(240) inz;

dcl-c cMsg_abnEnd 'Command ended in error. See job log for etails';

dcl-c cMEMBER_TEXT 'XML Install Package: %UTILITY%';

dcl-c cEOF *on;

dcl-s cALL_COLORS char(32) inz(x'2021242522232628292A2B2C2D2E3031343532333638393C3D3A3B3E272F373F');

dcl-s cALL_BLANKS like(cALL_COLORS) inz;

//  *ENTRY parameters
dcl-pi *n;
  scriptFile char(10); // script file
  scriptLib  char(10); // - library
  scriptMbr  char(10); // - member
  XML_file   char(10); // XML file
  XML_lib    char(10); // - library
  XML_mbr    char(10); // - member
  scrID      char(10); // application name
  encoding   char(10); // XML Encoding
  author     char(20); // appl author
end-pi;

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
// Open script file.
//---------------------------------------------------------------------
if (not openScript(scriptFile :
                   scriptLib  :
                   scriptMbr  ));
  sndMessage('CPF9898'   :
             cMsg_abnEnd :
             '*ESCAPE'   );
endif;

//---------------------------------------------------------------------
// Open XML file.
//---------------------------------------------------------------------
if (not openXML(XML_file   :
                XML_lib    :
                XML_mbr    :
                '*WRITE'   ));
  sndMessage('CPF9898'   :
             cMsg_abnEnd :
             '*ESCAPE'   );
endif;

//----------------------------------------------------------------
// generate xml header statement.
//----------------------------------------------------------------
writeXML('<?xml version=' + qd + '1.0'+
          qd + ' encoding=' + qd +
          %trim(Encoding)+qd+'?>'     );

//----------------------------------------------------------------
// Read down in script to get whether or not to generate the DTD .
//      XMLGENINC  XINCLUDE(*YES) *YES, *NO
//
// If user has selected to not include install program,
// then do not include DTD, install instructions, or install_pgm.
//----------------------------------------------------------------
dow (readScript(xScriptSource) <> cEOF);

  xScriptSource = rmvClRem(xScriptSource);  // remove comment
  if (xScriptSource = '');
    iter;
  endif;

  if (%scan('XMLGENINC': uCase(xScriptSource)) > 0);
    xinclude = getKwdData('XINCLUDE'    :
                          xScriptSource );
    leave;
  endif;

enddo;

exsr srLoadDTD;  // Load DTD

writeXML('<upload'+
         '  appname='    + qd +
                         %trimr(ScrID)
                         + qd +
         '  appauthor='  + qd +
                         %trim(author)
                         + qd +
         '  appblddate=' + qd +
                         %editc(*date:'Y')
                         + qd + '>'         );

if (xinclude='*YES');
  exsr srLoadInstr;  // Load instructions
  exsr srLoadInstPgm;  // Load install pgm
endif;

//---------------------------------------------------------------------
// Spin through script file and load data from tags as the occur.
//      XMLGENMBR  XMBR(XMLGEN) XMBRATR(CLP) XFROMSRCF(JCLSRC) +
//                   XFROMSRCL(JCRCMDS) XTOSRCF(QCLSRC) +
//                   XOBJTYPE(*PGM) +
//                   XPARAM(OPTION(*SRCDBG) USRPRF(*OWNER)) +
//                   XGENCRT(*YES) +
//                   XCND(aCondition)
//
//      XMLGENCMD  XCMD(CRTDTAARA DTAARA(&TOLIB/TEST) +
//                   TYPE(*CHAR) LEN(10) VALUE(A)) +
//                   XCND(aCondition) +
//                   XRLS(*EQ V5R1M0) +
//                   XDLTSPLF(*NONE)
//
//      XMLGENSQL  XCMD(SELECT * FROM MYLIB/MYFILE) +
//                   XCND(aCondition)
//
//      XMLGENCND  XMSG('Message presented to the user') +
//                   XVALUES(Y N) XVAR(*NONE)
//
//      XMLGENOBJD XOBJ(BASICS1) XLIB(*LIBL) XTYPE(*SRVPGM) +
//                   XRTNLIB(&BASICS1LIB) +
//                   XCND(aCondition)
//
//      XMLGENSET  XVAR(&VARNAME) +
//                   XVALUE(aValue) +
//                   XCND(aCondition)
//---------------------------------------------------------------------
setllScript(1);

dow (readScript(xScriptSource) <> cEOF);

  xScriptSource = rmvClRem(xScriptSource);  // remove comment
  if (xScriptSource = '');
    iter;
  endif;

  // Check for XMLGEN command ...
  select;
  // ... XMLGENMBR
  when (%scan('XMLGENMBR':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    if (string <> '');
      exsr srParseMbrVal;  // extract mbr script
      exsr srLoadMbr;  // load into xml
    endif;
  // ... XMLGENCMD
  when (%scan('XMLGENCMD':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    if (string <> '');
      exsr srAddTgtRls;  // add parm TGTRLS
      exsr srParseCmdVal;  // extract cmd script
      exsr srLoadExc;
    endif;
  // ... XMLGENSQL
  when (%scan('XMLGENSQL':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    exsr srParseSqlVal;  // extract sql script
    exsr srLoadSql;
  // ... XMLGENCND
  when (%scan('XMLGENCND':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    exsr srParseCndVal;  // extract cnd values
    exsr srLoadCnd;
  // ... XMLGENOBJD
  when (%scan('XMLGENOBJD':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    exsr srParseObjDVal;  // extract values
    exsr srLoadObjD;
  // ... XMLGENSET
  when (%scan('XMLGENSET':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    exsr srParseSetVal;  // extract values
    exsr srLoadSet;
  // ... XMLGENVRS
  when (%scan('XMLGENVRS':ucase(xScriptSource)) > 0);
    string = loadScriptString(xScriptSource);  // load into one string
    string = rmvClRem(string);  // remove comment
    string = fmtClCmd(string);  // format command
    exsr srParseVrsVal;  // extract values
    exsr srSetVersion;
  // ... others
  other;
    string = '';
  endsl;

enddo;

//----------------------------------------------------------------
// generate completed message code.
//----------------------------------------------------------------
writeXML('<sendmsg  sendmsgid=' + qd +
         'CPF9897' + qd + ' ' +
         'sendmsgtype = ' + qd +
         '*COMP     ' + qd + '>' +
         '<!' + ba + 'CDATA' + ba    );

writeXML('Application ' + %trimr(ScrID) +
         ' successfully installed.  '   );

writeXML(bb + bb + '>  </sendmsg>');

writeXML('</upload>');

closeScript();
closeXML();

*inlr=*on;
return;

//----------------------------------------------------------------
// Generate DTD validation specs, Install instructions and
// Install program.
//----------------------------------------------------------------
begsr srLoadDTD;

  for aa = 1 to %elem(ArryDTD);
    writeXML(ArryDTD(aa));
  endfor;

endsr;

//----------------------------------------------------------------
// load <upload attributes
// Note:  Change 'Craig Rutledge' to your name here.
//----------------------------------------------------------------
begsr srLoadInstr;

  //----------------------------------------------------------------
  // load <install_instructions>
  //  the bracket symbol is not available on all keyboards.
  //  (namely mine!) so I will use the hex values. BA=open  BB=close
  // Load instruction array to outfile.
  //----------------------------------------------------------------

  writeXML('<install_instructions>' +
           '<!' + ba + 'CDATA' + ba );

  for aa = 1 to %elem(ArryInstruct);
    writeXML(ArryInstruct(aa));
  endfor;
  // close brackets
  writeXML(bb + bb + '> ' +
           ' </install_instructions>');

endsr;

//----------------------------------------------------------------
// load <install_program>    Load RPG source array to outfile.
//----------------------------------------------------------------
begsr srLoadInstPgm;

  writeXML('<install_program>' +
           '<!' + ba + 'CDATA' + ba);

  // first line of the fully free-form install program; not part of the
  // compile-time data, because '**' starts a new set of compile-time data
  writeXML('**free');

  for aa = 1 to %elem(ArryInstPgm);
    writeXML(ArryInstPgm(aa));
  endfor;
  // close brackets
  writeXML(bb + bb + '> ' +
           ' </install_program>');
endsr;

//----------------------------------------------------------------
// Load member into xml output
//----------------------------------------------------------------
begsr srLoadMbr;

  //---------------------------------------------------------------------
  // Open member file.
  //---------------------------------------------------------------------
  if (not openMbr(xfromsrcf :
                  xfromsrcl :
                  xmbr      ));
    sndMessage('CPF9898'   :
               cMsg_abnEnd :
               '*ESCAPE'   );
  endif;

  //  send status message to user
  writeXML('<sendmsg  sendmsgid=' + qd +
           'CPF9897' + qd + ' ' +
           'sendmsgtype = ' + qd +
           '*STATUS   ' + qd + '>' +
           '<!' + ba + 'CDATA' + ba    );

  writeXML('Installing ' + %trimr(xmbr) +
           '  type ' + %trimr(xmbratr) +
           ' - in progress.'            );

  writeXML(bb + bb + '>  </sendmsg>');

  //  member attributes
  writeXML('<!-- START OF MEMBER  -->');

  writeXML('<mbr');
  // MBRNAME
  writeXML('mbrname =  ' + qd + xmbr + qd);
  // MBRTYPE
  writeXML('mbrtype =  ' + qd + xmbratr + qd);
  // MBRTEXT
  writeXML('mbrtext =  ' + qd +
           GetMbrTxt(xfromsrcf:xfromsrcl:xmbr)
           + qd                               );
  // SRCFILE
  writeXML('srcfile =  ' + qd + xtosrcf + qd);
  // SRCLIB
  writeXML('srclib  =  ' + qd + 'selected  '
           + qd                               );
  // SRCLEN
  writeXML('srclen  =  ' + qd +
            %editc(%dec(getMbrRcdLen:5:0): 'X')
           + qd                               );
  // CSSID
  writeXML('srccssid=  ' + qd +
            %editc(%dec(getMbrCCSID :5:0): 'X')
           + qd + '>'                         );

  //  ----------------------------------------------------------------------------------------
  //   load the member data into text file.
  //  -----------------------------------------------------------------------------------------
  writeXML('<copysrc>' +
           '<!' + ba + 'CDATA' + ba);

  //    ----------------------------------------------------------------
  //    read through the member loading source record to outfile
  //    ----------------------------------------------------------------
  dow (readMbr(xMbrSource) <> cEOF);
    xMbrSource = %xlate(cALL_COLORS
                        : cALL_BLANKS
                        : xMbrSource);
    writeXML(xMbrSource);
  enddo;

  closeMbr();

  // close brackets
  writeXML(bb + bb + '>  </copysrc>');
  writeXML('</mbr>');

  //    ----------------------------------------------------------------
  //    generate standard object creation code
  //    if flag is set to '*YES'
  //    ----------------------------------------------------------------
  if (xgencrt='*YES');
    if (xmbratr= 'CMD  ');
      exsr srCrtCmd;  // Create Command defin
    else;
      //**                callp     writeXML('<sendmsg  sendmsgid=' + qd +
      //**                                   'CPF9897' + qd + ' ' +
      //**                                   'sendmsgtype = ' + qd +
      //**                                   '*COMP     ' + qd + '>' +
      //**                                   '<!' + ba + 'CDATA' + ba    )
      writeXML('<compile  condition=' + qd +
               %trim(xcondition) + qd + '>' +
               '<!' + ba + 'CDATA' + ba);

      genSrcFile = ' SRCFILE(&tolib/' +
                   %trimr(xtosrcf) + ')';
      select;
      when (xmbratr = 'RPGLE    '  and
            xobjtype = '*PGM     ');
        string = 'CRTBNDRPG PGM(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile;

      when (xmbratr = 'SQLRPGLE '  and
            xobjtype = '*PGM     ');
        string = 'CRTSQLRPGI OBJ(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile  +
          ' COMMIT(*NONE)';

      when (xmbratr = 'RPG      '  and
            xobjtype = '*PGM     ');
        string = 'CRTRPGPGM PGM(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile;

      when (xmbratr = 'CLP      '  and
            xobjtype = '*PGM     ');
        string = 'CRTCLPGM PGM(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile;

      when (xmbratr = 'CLLE     '  and
            xobjtype = '*PGM     ');
        string = 'CRTBNDCL PGM(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile;

      when (xmbratr = 'PNLGRP    ');
        string = 'CRTPNLGRP PNLGRP(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile;

      when (xmbratr = 'DSPF      ');
        string = 'CRTDSPF FILE(&tolib/'+
          %trimr(xmbr) +')' + genSrcFile;

      when (xmbratr = 'PRTF      ');
        string = 'CRTPRTF FILE(&tolib/'+
          %trimr(xmbr) +')' + gensrcfile;

      when (xmbratr = 'PF        ');
        string = 'CRTPF FILE(&tolib/'+
          %trimr(xmbr) +')' + gensrcfile;

      when (xmbratr = 'LF        ');
        string = 'CRTLF FILE(&tolib/'+
          %trimr(xmbr) +')' + gensrcfile;
      endsl;

      // add XPARAM
      string = string + ' ' + %trim(xparam);

      // multiline command
      writeXMLString(string);

      // close brackets
      writeXML(bb + bb + '> ' +
               ' </compile>'  );
    endif;
  endif;

endsr;

//---------------------------------------------------------------------------------------------
// The command data was loaded into a single string.  This section
// will break the commands into 100 byte chuncks and write to xml.
//---------------------------------------------------------------------------------------------
begsr srLoadExc;

  writeXML('<qcmdexc' +
             ' condition=' + qd +
               %trim(xcondition) + qd +
             ' release=' + qd +
               %trim(xrelease) + qd +
             ' dltsplf=' + qd +
               %trim(xdltsplf) + qd +
             '>' +
             '<!' + ba + 'CDATA' + ba);

  writeXMLString(xcommand);

  // close brackets
  writeXML(bb + bb + '>  </qcmdexc>');

endsr;

//---------------------------------------------------------------------------------------------
// The sql-command data was loaded into a single string.  This section
// will break the commands into 100 byte chuncks and write to xml.
//---------------------------------------------------------------------------------------------
begsr srLoadSql;

  writeXML('<execsql  condition=' + qd +
           %trim(xcondition) + qd + '>' +
           '<!' + ba + 'CDATA' + ba);

  writeXMLString(xcommand);

  // close brackets
  writeXML(bb + bb + '>  </execsql>');

endsr;

//---------------------------------------------------------------------------------------------
// The condition data was loaded into a single string.  This section
// will break the data into 100 byte chuncks and write to xml.
//---------------------------------------------------------------------------------------------
begsr srLoadCnd;

  writeXMLString('<qrycond');
  writeXMLString('  msg=' + qd +
                      %trim(xmsg) + qd);
  writeXMLString('  values=' + qd +
                      %trim(xvalues) + qd);
  writeXMLString('  var=' + qd +
                      %trim(xvar) + qd + '>');
  writeXMLString('<!' + ba + 'CDATA' + ba );

  writeXML(bb + bb + '>  </qrycond>');

endsr;

//---------------------------------------------------------------------------------------------
// The retrieve object description data was loaded into a single string.  This section
// will break the data into 100 byte chuncks and write to xml.
//---------------------------------------------------------------------------------------------
begsr srLoadObjD;

  xmlString = '<rtvobjd ' +
        ' condition=' +
             Qd + %trim(xcondition) + Qd +
        ' obj='     + Qd + xobj     + Qd +
        ' lib='     + Qd + xlib     + Qd +
        ' objtype=' + Qd + xobjtype + Qd;

  if (xrtnlib <> '');
    xmlString = xmlString +
          ' rtnlib=' + Qd + xrtnlib + Qd;
  endif;

  xmlString = xmlString + '>';

  writeXMLString(xmlString);

  writeXMLString('<!' + ba + 'CDATA' + ba);

  writeXML(bb + bb + '>  </rtvobjd>');

endsr;

//---------------------------------------------------------------------------------------------
// The 'set' data was loaded into a single string.  This section
// will break the data into 100 byte chuncks and write to xml.
//---------------------------------------------------------------------------------------------
begsr srLoadSet;

  xmlString = '<chgvar  ' +
        ' condition=' +
             Qd + %trim(xcondition) + Qd +
        ' var='     + Qd + xvar     + Qd +
        ' value='   + Qd + xvalue   + Qd;

  xmlString = xmlString + '>';

  writeXMLString(xmlString);

  writeXMLString('<!' + ba + 'CDATA' + ba);

  writeXML(bb + bb + '>  </chgvar>');

endsr;

//---------------------------------------------------------------------------------------------
// Retrieves and sets the version number of the utility.
//---------------------------------------------------------------------------------------------
begsr srSetVersion;

  text = replace(
          '%UTILITY%': cMEMBER_TEXT: scriptMbr);
  text.version = getVersionInfo(
                    xsrcfile: xsrclib: xsrcmbr);

  clCommand = 'CHGPFM +
                 FILE(' +
                   %trim(XML_lib) + '/' +
                   %trim(XML_file) + ') +
                 MBR(' +
                   %trim(XML_mbr) + ') +
                 TEXT(''' + %trim(text) + ''')';

  system(clCommand);

endsr;

//---------------------------------------------------------------------------------------------
// extract values from mbr script command
// xcondition     s             10                                         compile condition
// xmbr           s             10                                         member name
// xmbratr        s             10                                         source mbr attr
// xfromsrcf      s             10                                         copy from src file
// xfromsrcl      s             10                                         copy from src lib
// xtosrcf        s             10                                         copy to src file
// xobjtype       s              7                                         object type
// xgencrt        s              4                                         gen compile code?
// xparam         s            200                                         optional parameter
//---------------------------------------------------------------------------------------------
begsr srParseMbrVal;

  xcondition = rtvCondition(string);

  xmbr       = getKwdData('XMBR'   : string);

  xmbratr    = getKwdData('XMBRATR': string);

  xfromsrcf  = getKwdData('XFROMSRCF': string);

  xfromsrcl  = getKwdData('XFROMSRCL': string);

  xtosrcf    = getKwdData('XTOSRCF'  : string);

  xobjtype   = getKwdData('XOBJTYPE' : string);

  xgencrt    = getKwdData('XGENCRT'  : string);

  xparam     = getKwdData('XPARAM'   : string);

  if (xparam = '*BLANK');
    xparam = ' ';
  else;
    xparam = rmvQuotes(%trim(xparam));
  endif;

endsr;

//---------------------------------------------------------------------------------------------
// extract values from cmd script command
// xcondition     s             10                                         compile condition
// xcommand       s           2000                                         cl command
// xrelease       s             10                                         i5 version
//---------------------------------------------------------------------------------------------
begsr srParseCmdVal;

  xcondition = rtvCondition(string);

  xcommand = getKwdData('XCMD'     : string);
  xcommand = rmvQuotes(xcommand);
  xcommand = replace('&TOLIB'  :
                     xcommand  :
                     '&tolib'  );
  //    Remove *IMMED from BNDSRVPGM parameter
  xcommand = chgBndSrvPgmParm(xcommand);

  xrelease = getKwdData('XRLS'     : string);

  if (xrelease = '');
    xrelease = '*CURRENT';
  endif;

  xdltsplf = getKwdData('XDLTSPLF' : string);

  if (xdltsplf = '');
    xdltsplf = '*NONE';
  endif;

endsr;

//---------------------------------------------------------------------------------------------
// add parameter TGTRLS(*CURRENT) to command
// xcommand       s           2000                                         cl command
//---------------------------------------------------------------------------------------------
begsr srAddTgtRls;

  if (not startsWith('CRTRPGMOD': xcommand) and  // | RPG
      not startsWith('CRTRPGPGM': xcommand) and  // |
      not startsWith('CRTBNDRPG': xcommand) and  // |
      not startsWith('CRTCLMOD' : xcommand) and  // | CL
      not startsWith('CRTCLPGM' : xcommand) and  // |
      not startsWith('CRTBNDCL' : xcommand) and  // |
      not startsWith('CRTCMOD'  : xcommand) and  // | C
      not startsWith('CRTBNDC'  : xcommand) and  // |
      not startsWith('CRTPGM'   : xcommand));  // | Pgm
    leavesr;
  endif;

  if (%scan('TGTRLS(': xcommand) = 0);
    leavesr;
  endif;

  xcommand = xcommand + ' TGTRLS(*CURRENT)';

endsr;

//---------------------------------------------------------------------------------------------
// extract values from sql script command
// xcondition     s             10                                         compile condition
// xcommand       s           2000                                         sql statement
//---------------------------------------------------------------------------------------------
begsr srParseSqlVal;

  xcondition = rtvCondition(string);

  xcommand  = getKwdData('XSQL'     : string);

  xcommand = rmvQuotes(xcommand);

  xcommand = rmvDblQuotes(xcommand);

  xcommand = replace('&TOLIB'  :
                     xcommand  :
                     '&tolib'  );

endsr;

//---------------------------------------------------------------------------------------------
// extract values from condition script command
// xmsg           s             52                                         cond. msg text
// xvalues        s                                                        cond. values
//---------------------------------------------------------------------------------------------
begsr srParseCndVal;

  xmsg   = getKwdData('XMSG'    : string);

  values = getKwdData('XVALUES'  : string) +
           x'00';

  pValue = strtok(values: ' ');

  cc = 0;
  dow (pValue <> *null);
    cc = cc + 1;
    xvalues_entry(cc) = %str(pValue);
    pValue = strtok(*null: ' ');
  enddo;

  xcndData = ' msg=' + Qd +
             %trim(xmsg) + Qd +
             ' values=' + Qd +
             %trim(xvalues) + Qd;

  xvar = getFldName('XVAR': string);

endsr;

//---------------------------------------------------------------------------------------------
// extract values from retrieve object description script command
// xobj           s             10                                         object name
// xlib           s             10                                         library name
// xobjtype       s             10                                         object type
// xcondition     s            200                                         compile condition
//---------------------------------------------------------------------------------------------
begsr srParseObjDVal;

  xobj       = getKwdData('XOBJ'     : string);
  xlib       = getKwdData('XLIB'     : string);
  xobjtype   = getKwdData('XOBJTYPE' : string);
  xcondition = rtvCondition(string);
  xrtnlib    = getFldName('XRTNLIB'  : string);

endsr;

//---------------------------------------------------------------------------------------------
// extract values from 'set' script command
// xvar           s             10                                         variable name
// xvalue         s             64                                         variable value
// xcondition     s            200                                         compile condition
//---------------------------------------------------------------------------------------------
begsr srParseSetVal;

  xvar       = getFldName('XVAR'     : string);
  xvalue     = getKwdData('XVALUE'   : string);
  xcondition = rtvCondition(string);

endsr;

//---------------------------------------------------------------------------------------------
// extract values from 'vrs' script command
// xvar           s             10                                         variable name
// xvalue         s             64                                         variable value
// xcondition     s            200                                         compile condition
//---------------------------------------------------------------------------------------------
begsr srParseVrsVal;

  xsrcfile = getKwdData('XSRCFILE' : string);
  xsrclib  = getKwdData('XSRCLIB'  : string);
  xsrcmbr  = getKwdData('XSRCMBR'  : string);
  xrtnvrs  = getFldName('XRTNVRS'  : string);

endsr;

//---------------------------------------------------------------------------------------------
// Extract command definitions
//---------------------------------------------------------------------------------------------
begsr srCrtCmd;

  clear errCode;

  QCDRCMDI(vrcvar           :
           %size(vrcvar)    :
           'CMDI0100'       :
           xmbr + xfromsrcl :
           errCode          );

  vCPGM = %subst(vRCVAR:29:10);
  vCLIB = %subst(vRCVAR:39:10);
  vSFILE= %subst(vRCVAR:49:10);
  vSLIB = %subst(vRCVAR:59:10);
  vSMBR = %subst(vRCVAR:69:10);
  vVPGM = %subst(vRCVAR:79:10);
  vVLIB = %subst(vRCVAR:89:10);
  vMODE = %subst(vRCVAR:99:10);
  vALW  = %subst(vRCVAR:109:10);

  if (%subst(vrcvar:124:1) = '0');
    valwlm = '*NO ';
  endif;

  vPMFIL = %subst(vRCVAR:129:10);
  vPMLIB = %subst(vRCVAR:139:10);
  vMSFIL = %subst(vRCVAR:149:10);
  vMSLIB = %subst(vRCVAR:159:10);
  vHLPNL = %subst(vRCVAR:169:10);
  vHLIB  = %subst(vRCVAR:179:10);
  vHLPID = %subst(vRCVAR:189:10);
  vPLIB  = %subst(vRCVAR:229:10);
  vOVPGM = %subst(vRCVAR:239:10);
  vOVLIB = %subst(vRCVAR:249:10);
  vTEXT  = %subst(vRCVAR:265:50);

  //     ----------------------------------------------------------------
  //     generate Command creation code
  //    ----------------------------------------------------------------
  string = 'XMLGENCMD XCMD(''CRTCMD ' +
           'CMD(&tolib/' + %trimr(xmbr)  + ')';

  // - -
  //  CMD program
  if (vCLIB = '*LIBL');
    string = string +
      ' PGM(' + %trimr(vCLIB) + '/' +
              %trimr(vCPGM)  + ')';
  else;
    string = string +
      ' PGM(&tolib/' + %trimr(vCPGM)  + ')';
  endif;

  // - -
  //  source file
  string = string +
    ' SRCFILE(&tolib/' + %trim(xtosrcf) +
          ') SRCMBR(' +
          %trimr(xmbr)  + ')'  +
    ' ALWLMTUSR(' +  %trimr(vALWLM)  + ')' +
    ' HLPID(' +  %trimr(vHLPID)  + ')';
  // - -
  //  Validity checking program
  if (vVPGM > *blanks and
      vVPGM <> '*NONE  ');
    if (vVLIB = '*LIBL');
      string = string +
        ' VLDCKR(' + %trimr(vVLIB) + '/' +
                   %trimr(vVPGM)  + ')';
    else;
      string = string +
        ' VLDCKR(&tolib/' + %trimr(vVPGM)  + ')';
    endif;
  endif;
  // - -
  //  Mode in which valid
  string = string + ' MODE(';
  if (vMODE_PROD    = '1');
    string = string + ' *PROD';
  endif;
  if (vMODE_DEBUG   = '1');
    string = string + ' *DEBUG';
  endif;
  if (vMODE_SERVICE = '1');
    string = string + ' *SERVICE';
  endif;
  string = string + ')';
  // - -
  //  Where allowed to run
  string = string + ' ALLOW(';
  if (vALW_BPGM     = '1');
    string = string + ' *BPGM';
  endif;
  if (vALW_IPGM     = '1');
    string = string + ' *IPGM';
  endif;
  if (vALW_EXEC     = '1');
    string = string + ' *EXEC';
  endif;
  if (vALW_INTERACT = '1');
    string = string + ' *INTERACT';
  endif;
  if (vALW_BATCH    = '1');
    string = string + ' *BATCH';
  endif;
  if (vALW_BREXX    = '1');
    string = string + ' *BREXX';
  endif;
  if (vALW_IREXX    = '1');
    string = string + ' *IREXX';
  endif;
  if (vALW_BMOD     = '1');
    string = string + ' *BMOD';
  endif;
  if (vALW_IMOD     = '1');
    string = string + ' *IMOD';
  endif;
  string = string + ')';
  // - -
  //  Message file for prompt text
  if (vPMFIL > *blanks and
      vPMFIL <> '*NONE  ');
    if (vPMLIB = '*LIBL');
      string = string +
        ' PMTFILE(' + %trimr(vPMLIB) + '/' +
                   %trimr(vPMFIL)  + ')';
    else;
      string = string +
        ' PMTFILE(&tolib/' + %trimr(vPMFIL)  + ')';
    endif;
  endif;
  // - -
  //  Help panel group
  if (vHLPNL > *blanks and
      vHLPNL <> '*NONE  ');
    if (vHLIB = '*LIBL');
      string = string +
        ' HLPPNLGRP(' + %trimr(vHLIB) + '/' +
                   %trimr(vHLPNL)  + ')';
    else;
      string = string +
        ' HLPPNLGRP(&tolib/' + %trimr(vHLPNL)  + ')';
    endif;
  endif;

  // - -
  //  Product library
  if ((vPLIB = '*NOCHG')  or
      (vPLIB = '*NONE' ));
    string = string +
      ' PRDLIB(' + %trimr(vPLIB) + ')';
  else;
    string = string +
      ' PRDLIB(&tolib)';
  endif;
  // - -
  //  Prompt override program
  if (vOVPGM > *blanks and
      vOVPGM <> '*NONE  ');
    if (vOVLIB = '*LIBL');
      string = string +
        ' PMTOVRPGM(' + %trimr(vOVLIB) + '/' +
                   %trimr(vOVPGM)  + ')';
    else;
      string = string +
        ' PMTOVRPGM(&tolib/' + %trimr(vOVPGM)  + ')';
    endif;
  endif;
  // - -
  //  Text
  string = string + ' TEXT(*SRCMBRTXT)';
  // - -
  //  Additional parameters
  string = string + ' ' + %trim(xparam) + ') '+
           'XCND(' + %trim(xcondition) + ')';
  exsr srParseCmdVal;  // extract cmd script
  exsr srLoadExc;

endsr;

//---------------------------------------------------------------------------------------------
//  Get condition from command string
//---------------------------------------------------------------------------------------------
dcl-proc rtvCondition;
  dcl-pi *n like(string_t);
    i_string like(string_t) value;
  end-pi;

  //  return value
  dcl-s condition like(string_t);

  //  local fields
  dcl-s tmpStr like(condition) inz;
  dcl-s pValue pointer inz;
  //-------------------------------------------------------------------*

  tmpStr = getKwdData('XCND'    : i_string);

  if (tmpStr = '');
    condition = '*NONE';
  else;
    pValue = strtok(tmpStr: ' ');
    dow (pValue <> *null);
      if (condition = '');
        condition = rmvQuotes(%trim(%str(pValue)));
      else;
        condition = %trimr(condition) + ' ' +
                    rmvQuotes(%trim(%str(pValue)));
      endif;
      pValue = strtok(*null: ' ');
    enddo;
  endif;

  return condition;

end-proc;

//---------------------------------------------------------------------------------------------
//  Remove *IMMED from BNDSRVPGM parameter
//---------------------------------------------------------------------------------------------
dcl-proc chgBndSrvPgmParm;
  dcl-pi *n like(string);
    i_command like(string) const;
  end-pi;

  //  return value
  dcl-s command like(string_t) inz;

  //  local fields
  dcl-s x int(10) inz;
  dcl-s y int(10) inz;
  dcl-s k int(10) inz;
  dcl-s i int(10) inz;
  dcl-c BNDSRVPGM 'BNDSRVPGM';
  dcl-c IMMED '*IMMED';
  //-------------------------------------------------------------------*

  x = %scan(BNDSRVPGM + '(': i_command);
  if (x = 0);
    return i_command;
  endif;

  x = %scan('(': i_command: x);
  y = x;
  dou (k = 0 or y > %len(i_command));
    select;
    when (%subst(i_command: y: 1) = '(');
      k = k + 1;
    when (%subst(i_command: y: 1) = ')');
      k = k - 1;
    endsl;
    if (k <> 0);
      y = y + 1;
    endif;
  enddo;

  if (k <> 0);
    return i_command;
  endif;

  command = i_command;

  //  remove *IMMED between the parentheses x and y only
  i = %scan(IMMED: command: x);
  dow (i > 0 and i < y);
    command = %replace('': command: i: %len(IMMED));
    y = y - %len(IMMED);
    i = %scan(IMMED: command: x);
  enddo;

  return command;

end-proc;

** ctdata(ArryDTD)        Document template
     <!-- Embedded DTD for validation -->
     <!DOCTYPE upload [
     <!ELEMENT compile (#PCDATA)>
     <!ATTLIST compile
      condition CDATA #REQUIRED
     >
     <!ELEMENT copysrc (#PCDATA)>
     <!ELEMENT install_instructions (#PCDATA)>
     <!ELEMENT install_program (#PCDATA)>
     <!ELEMENT mbr (copysrc)>
     <!ATTLIST mbr
      mbrname CDATA #REQUIRED
      mbrtype CDATA #REQUIRED
      mbrtext CDATA #REQUIRED
      srcfile CDATA #REQUIRED
      srclib CDATA #REQUIRED
      srclen CDATA #REQUIRED
      srccssid CDATA #REQUIRED
     >
     <!ELEMENT qcmdexc (#PCDATA)>
     <!ATTLIST qcmdexc
      condition CDATA #REQUIRED
      release CDATA #REQUIRED
      dltsplf CDATA #REQUIRED
     >
     <!ELEMENT qrycond (#PCDATA)>
     <!ATTLIST qrycond
      msg CDATA #REQUIRED
      values CDATA #REQUIRED
      var CDATA #REQUIRED
     >
     <!ELEMENT sendmsg (#PCDATA)>
     <!ATTLIST sendmsg
      sendmsgid CDATA #REQUIRED
      sendmsgtype CDATA #REQUIRED
     >
     <!ELEMENT rtvobjd (#PCDATA)>
     <!ATTLIST rtvobjd
      condition CDATA #REQUIRED
      obj CDATA #REQUIRED
      lib CDATA #REQUIRED
      objtype CDATA #REQUIRED
      rtnlib CDATA #IMPLIED
     >
     <!ELEMENT upload (install_instructions | install_program | qrycond |
                       qcmdexc | sendmsg | mbr | compile | rtvobjd | chgvar)+>
     <!ATTLIST upload
      appname CDATA #REQUIRED
      appauthor CDATA #REQUIRED
      appblddate CDATA #REQUIRED
     >
     ]>
** ctdata(ArryInstruct)   install_instructions
     *----------------------------------------------------------------      ------
     *  1. Upload entire XML to your AS/400 to a source file 112 long, into any mbr
     *     name not in this XML (suggest member name like ABCX or XYZX). The source
     *     file must be in the library where source and objects are to be installed.
     *
     *  2. If you have XMLPREVIEW installed, skip to step 3.
     *
     *     Copy the text between the start tag <install_program> and the end
     *     tag </install_program> into any member name (your choice)
     *     in file QRPGLESRC member type RPGLE.   CRTBNDRPG to compile.
     *     NOTE: You need extract the install program only once, this same program
     *           will install any upload on this page.
     *
     *  3. Call the install program (or execute XmlPrevew) passing these 3 parms.
     *       'your-member-name you uploaded this text into'
     *       'your-source-file-name the member is in'
     *       'your-library-name the source file is in'
     *
     *  The various source members will be extracted and the objects required
     *   for the application will be created in your-library-name.
     *----------------------------------------------------------------      ------
** ctdata(ArryInstPgm)    install_program
// /// START OF INSTALL PGM HERE   ************************** ///
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
// /// END   OF INSTALL PGM HERE   ****************************************** ///
// /// do not copy past this point ///
