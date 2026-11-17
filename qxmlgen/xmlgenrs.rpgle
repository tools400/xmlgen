**free
//%METADATA                                                      *
// %TEXT XMLGENRV + XMLGENR service module                       *
//%EMETADATA                                                     *
ctl-opt nomain bnddir('QC2LE');
//---------------------------------------------------------------------------------------------
// xmlgenrs - XMLGENRV + XMLGENR service module
// Copyright (C) 01/20/2002  Thomas Raddatz   <thomas.raddatz@tools400.de>
//
// This program is free software, you can redistribute it and/or modify it under the terms
// of the GNU General Public License as published by the Free Software Foundation.
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
// >>END-PRE-COMPILER<<
//--------------------------------------------------------------------------------------------
/copy 'qxmlgen/copyright.rpgleinc'

//---------------------------------------------------------------------------------------------
//
// Provide the following common used procedures:
//
//---------------------------------------------------------------------------------------------
dcl-f script disk(252) usropn infds(script_); // script file
dcl-f xml disk(252) usage(*update: *delete: *output) usropn infds(xml_); // xml file
dcl-f mbr disk(252) usropn infds(mbr_); // member

//  script IO buffer
dcl-ds iScript;
  iScriptSrcSeq zoned(6: 2) pos(1);
  iScriptSrcDat zoned(6: 0) pos(7);
  iScriptSrcDta char(240) pos(13);
end-ds;

//  script file information data structure
dcl-ds script_;
  script_open    char(1) pos(9);
  script_status  zoned(5: 0) pos(11);
  script_file    char(10) pos(83);
  script_library char(10) pos(93);
  script_rcdLen  int(5) pos(125);
  script_member  char(10) pos(129);
  script_ccsid   int(5) pos(218);
  script_rcdNbr  int(10) pos(397);
end-ds;

//  XML IO buffer
dcl-ds iXML;
  iXMLSrcSeq zoned(6: 2) pos(1);
  iXMLSrcDat zoned(6: 0) pos(7);
  iXMLSrcDta char(240) pos(13);
end-ds;

//  XML file information data structure
dcl-ds XML_;
  XML_open    char(1) pos(9);
  XML_status  zoned(5: 0) pos(11);
  XML_file    char(10) pos(83);
  XML_library char(10) pos(93);
  XML_rcdLen  int(5) pos(125);
  XML_member  char(10) pos(129);
  XML_ccsid   int(5) pos(218);
  XML_rcdNbr  int(10) pos(397);
end-ds;

//  mbr IO buffer
dcl-ds iMbr;
  iMbrSrcSeq zoned(6: 2) pos(1);
  iMbrSrcDat zoned(6: 0) pos(7);
  iMbrSrcDta char(240) pos(13);
end-ds;

//  mbr file information data structure
dcl-ds mbr_;
  mbr_open    char(1) pos(9);
  mbr_status  zoned(5: 0) pos(11);
  mbr_file    char(10) pos(83);
  mbr_library char(10) pos(93);
  mbr_rcdLen  int(5) pos(125);
  mbr_member  char(10) pos(129);
  mbr_ccsid   uns(5) pos(218);
  mbr_rcdNbr  int(10) pos(397);
end-ds;

//---------------------------------------------------------------------------------------
//  Exported prototypes:
//---------------------------------------------------------------------------------------
/copy 'qxmlgen/xmlgenrs_h.rpgleinc'

//---------------------------------------------------------------------------------------
//  Imported procedures and functions:
//---------------------------------------------------------------------------------------

/copy 'qxmlgen/regex.rpgleinc'

// Define function prototype to test for omitted arguments
dcl-pr ceetsta extproc('CEETSTA');
  o_isPresent int(10);
  i_ArgNumber int(10) const;
  o_fc        char(12) options(*omit);
end-pr;

// Define function prototype execute cl commands
dcl-pr system int(10) extproc('system');
  i_cmd pointer options(*string) value;
end-pr;

dcl-s EXCP_MSGID char(7) import('_EXCP_MSGID');

// Define function prototype to retrieve member description
dcl-pr qusrmbrd extpgm('QUSRMBRD');
  o_rcvVar    char(32767) options(*varsize);
  i_lenRcvVar int(10) const;
  i_format    char(8) const;
  i_qFile     char(20) const;
  i_mbr       char(10);
  i_override  char(1) const;
  io_errCode  char(32767) options(*varsize);
end-pr;

//---------------------------------------------------------------------------------------
//  Global fields
//---------------------------------------------------------------------------------------
dcl-s g_XMLMode char(10) inz('*N');
dcl-s g_XMLSrcSeq int(10) inz;

//---------------------------------------------------------------------------------------
//  Open script file
//---------------------------------------------------------------------------------------
dcl-proc openScript export;
  dcl-pi *n ind;
    i_file char(10) value;
    i_lib  char(10) value;
    i_mbr  char(10) value;
  end-pi;

  //  return value
  dcl-s isOpen ind inz(*off);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (not chkobj(i_lib: '*LIBL': '*LIB'));
    sndMessage('CPF9897'              :
               '0000 Library ' +
                %trim(i_lib) +
               ' was not found'       :
               '*DIAG'                );
    isOpen = *off;
  elseif (not chkobj(i_file: i_lib: '*FILE'));
    sndMessage('CPF9897'              :
               '0000 Source File ' +
                %trim(i_file) +
               ' was not found in ' +
                %trim(i_lib)          :
               '*DIAG'                );
    isOpen = *off;
  elseif (not chkobj(i_file: i_lib: '*FILE': i_mbr));
    sndMessage('CPF9897'              :
               '0000 Member ' +
                %trim(i_mbr) +
               ' was not found in ' +
                %trim(i_lib) + '/' +
                %trim(i_file)         :
               '*DIAG'                );
    isOpen = *off;
  else;
    system(
      'OVRDBF FILE(' +
                'SCRIPT' +
            ') ' +
            'TOFILE(' +
                %trimr(i_lib ) + '/' +
                %trimr(i_file) +
            ') ' +
            'MBR(' +
                %trim(i_mbr) +
            ') ' +
            'OVRSCOPE(' +
                '*CALLLVL' +
            ') '
          );
    open script;  // OPEN MEMBER

    isOpen = *on;
  endif;

  return isOpen;

end-proc;

//---------------------------------------------------------------------------------------
//  Setll in script file
//---------------------------------------------------------------------------------------
dcl-proc setllScript export;
  dcl-pi *n;
    i_rcdNbr int(10) value;
  end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  setll i_rcdNbr script;

  return;

end-proc;

//---------------------------------------------------------------------------------------
//  Read from script file
//---------------------------------------------------------------------------------------
dcl-proc readScript export;
  dcl-pi *n ind;
    o_line varchar(240);
  end-pi;

  //  return value
  dcl-s isEOF ind inz;

  //  local fields
  dcl-s dataLen int(10) inz;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  dataLen = script_rcdLen
          - %size(iScriptSrcSeq)
          - %size(iScriptSrcDat);

  read script iScript;
  if (%eof(script));
    o_line = '';
    isEOF  = *on;
  else;
    o_line = %subst(iScriptSrcDta :
                    1             :
                    dataLen       );
    isEOF  = *off;
  endif;

  return isEOF;

end-proc;

//---------------------------------------------------------------------------------------
//  Read a multi-line string from script file
//---------------------------------------------------------------------------------------
dcl-proc loadScriptString export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_line varchar(240) value;
  end-pi;

  //  return value
  dcl-s string varchar(2000) inz;

  //  local fields
  dcl-s allLoadedFlg ind inz;
  dcl-s cc int(10) inz;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(string)     :
         'Size of ''string'' does not match' );

  clear string;
  allLoadedFlg=*off;

  dou (allLoadedFlg=*on);
    for cc=%len(i_line) downto 1;

      if (%subst(i_line:cc:1) >' ');
        if (%subst(i_line:cc:1) ='+');
          %subst(i_line:cc:1) =' ';
        else;
          allLoadedFlg=*on;
        endif;
        leave;
      endif;

    endfor;

    string = string +
      %trim(i_line) + ' ';

    if (allLoadedFlg=*off);
      if (readScript(i_line) = *on);
        allLoadedFlg=*on;
      endif;
    endif;
  enddo;

  return %trimr(string);

end-proc;

//---------------------------------------------------------------------------------------
//  Close script file
//---------------------------------------------------------------------------------------
dcl-proc closeScript export;
  dcl-pi *n end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  close script;  // CLOSE MEMBER

  return;

end-proc;

//---------------------------------------------------------------------------------------
//  Open XML file
//---------------------------------------------------------------------------------------
dcl-proc openXML export;
  dcl-pi *n ind;
    i_file char(10) value;
    i_lib  char(10) value;
    i_mbr  char(10) value;
    i_mode char(10) value;
  end-pi;

  //  return value
  dcl-s isOpen ind inz(*off);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(i_mode = '*WRITE' or i_mode = '*READ':
    'Mode ' + i_mode + ' not valid for file XML');

  if (not chkobj(i_lib: '*LIBL': '*LIB'));
    sndMessage('CPF9897'              :
               '0000 Library ' +
                %trim(i_lib) +
               ' was not found'       :
               '*DIAG'                );
    isOpen = *off;
  elseif (not chkobj(i_file: i_lib: '*FILE'));
    sndMessage('CPF9897'              :
               '0000 Source File ' +
                %trim(i_file) +
               ' was not found in ' +
                %trim(i_lib)          :
               '*DIAG'                );
    isOpen = *off;
  elseif (not chkobj(i_file: i_lib: '*FILE': i_mbr));
    sndMessage('CPF9897'              :
               '0000 Member ' +
                %trim(i_mbr) +
               ' was not found in ' +
                %trim(i_lib) + '/' +
                %trim(i_file)         :
               '*DIAG'                );
    isOpen = *off;
  else;
    system(
      'OVRDBF FILE(' +
                'XML' +
            ') ' +
            'TOFILE(' +
                %trimr(i_lib ) + '/' +
                %trimr(i_file) +
            ') ' +
            'MBR(' +
                %trim(i_mbr) +
            ') ' +
            'OVRSCOPE(' +
                '*CALLLVL' +
            ') '
          );
    open xml;  // OPEN MEMBER

    g_XMLMode   = i_mode;
    g_XMLSrcSeq = 0;

    isOpen      = *on;
  endif;

  iXMLSrcSeq = 0;

  return isOpen;

end-proc;

//---------------------------------------------------------------------------------------
//  Read from XML file
//---------------------------------------------------------------------------------------
dcl-proc readXML export;
  dcl-pi *n ind;
    o_line varchar(240);
  end-pi;

  //  return value
  dcl-s isEOF ind inz;

  //  local fields
  dcl-s dataLen int(10) inz;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(g_XMLMode = '*READ'                 :
    'File XML not opened for *READ operations' );

  dataLen = xml_rcdLen
          - %size(iXMLSrcSeq)
          - %size(iXMLSrcDat);

  read XML iXML;
  if (%eof(XML));
    o_line = '';
    isEOF  = *on;
  else;
    o_line = %subst(iXMLSrcDta :
                    1          :
                    dataLen    );
    isEOF  = *off;
  endif;

  return isEOF;

end-proc;

//---------------------------------------------------------------------------------------
//  Write to XML file
//---------------------------------------------------------------------------------------
dcl-proc writeXML export;
  dcl-pi *n;
    i_line varchar(240) value;
  end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(g_XMLMode = '*WRITE'                :
    'File XML not opened for *WRITE operations');

  g_XMLSrcSeq = g_XMLSrcSeq + .01;

  iXMLSrcSeq = g_XMLSrcSeq;
  iXMLSrcDat = 0;
  iXMLSrcDta = i_line;

  write XML iXML;

  return;

end-proc;

//---------------------------------------------------------------------------------------
//  Write a multi-line string to XML file
//---------------------------------------------------------------------------------------
dcl-proc writeXMLString export;
  dcl-pi *n;
    i_string varchar(2000) value; // like(string)
  end-pi;

  //  local fields
  dcl-s start int(10) inz;
  dcl-s len int(10) inz;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(i_string)    :
         'Size of ''i_string'' does not match');

  start = 1;

  dow (start <= %len(i_string));

    if ((start + 100 - 1) <= %len(i_string));
      len = 100;
    else;
      len = %len(i_string) - start + 1;
    endif;

    writeXML(%subst(i_string: start: len));
    start = start + 100;
  enddo;

  return;

end-proc;

//---------------------------------------------------------------------------------------
//  Close XML file
//---------------------------------------------------------------------------------------
dcl-proc closeXML export;
  dcl-pi *n end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  close xml;  // CLOSE MEMBER

  g_XMLMode = '*N';

  return;

end-proc;
//---------------------------------------------------------------------------------------
//  Open member file
//---------------------------------------------------------------------------------------
dcl-proc openMbr export;
  dcl-pi *n ind;
    i_file char(10) value;
    i_lib  char(10) value;
    i_mbr  char(10) value;
  end-pi;

  //  return value
  dcl-s isOpen ind inz(*off);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (not chkobj(i_lib: '*LIBL': '*LIB'));
    sndMessage('CPF9897'              :
               '0000 Library ' +
                %trim(i_lib) +
               ' was not found'       :
               '*DIAG'                );
    isOpen = *off;
  elseif (not chkobj(i_file: i_lib: '*FILE'));
    sndMessage('CPF9897'              :
               '0000 Source File ' +
                %trim(i_file) +
               ' was not found in ' +
                %trim(i_lib)          :
               '*DIAG'                );
    isOpen = *off;
  elseif (not chkobj(i_file: i_lib: '*FILE': i_mbr));
    sndMessage('CPF9897'              :
               '0000 Member ' +
                %trim(i_mbr) +
               ' was not found in ' +
                %trim(i_lib) + '/' +
                %trim(i_file)         :
               '*DIAG'                );
    isOpen = *off;
  else;
    system(
      'OVRDBF FILE(' +
                'MBR' +
            ') ' +
            'TOFILE(' +
                %trimr(i_lib ) + '/' +
                %trimr(i_file) +
            ') ' +
            'MBR(' +
                %trim(i_mbr) +
            ') ' +
            'OVRSCOPE(' +
                '*CALLLVL' +
            ') '
          );
    open mbr;  // OPEN MEMBER

    isOpen = *on;
  endif;

  return isOpen;

end-proc;

//---------------------------------------------------------------------------------------
//  Read from member file
//---------------------------------------------------------------------------------------
dcl-proc readMbr export;
  dcl-pi *n ind;
    o_line varchar(240);
  end-pi;

  //  return value
  dcl-s isEOF ind inz;

  //  local fields
  dcl-s dataLen int(10) inz;
  dcl-c cLOW_ x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C+
    1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A+
    3B3C3D3E3F';
  dcl-c cBLANK x'4040404040404040404040404040404040404040404040404040404040+
    404040404040404040404040404040404040404040404040404040404040+
    4040404040';
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  dataLen = mbr_rcdLen
          - %size(iMbrSrcSeq)
          - %size(iMbrSrcDat);

  read mbr iMbr;
  if (%eof(mbr));
    o_line = '';
    isEOF  = *on;
  else;
    o_line = %subst(iMbrSrcDta :
                    1          :
                    dataLen    );
    o_line = %xlate(cLOW_   : cBLANK: o_line);
    isEOF  = *off;
  endif;

  return isEOF;

end-proc;

//---------------------------------------------------------------------------------------
//  Close member file
//---------------------------------------------------------------------------------------
dcl-proc closeMbr export;
  dcl-pi *n end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  close mbr;  // CLOSE MEMBER

  return;

end-proc;

//---------------------------------------------------------------------------------------
//  Get member CCSID.
//---------------------------------------------------------------------------------------
dcl-proc getMbrCCSID export;
  dcl-pi *n uns(5) end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  return mbr_ccsid;

end-proc;

//---------------------------------------------------------------------------------------
//  Get member record length.
//---------------------------------------------------------------------------------------
dcl-proc getMbrRcdLen export;
  dcl-pi *n int(5) end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  return mbr_rcdLen;

end-proc;
//---------------------------------------------------------------------------------------
//  Remove preceding and trailing quotes from a string
//---------------------------------------------------------------------------------------
dcl-proc rmvQuotes export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_string varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s string varchar(2000) inz;

  //  quotes
  dcl-c Qs '''';
  dcl-c Qd '"';
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(i_string)    :
         'Size of ''i_string'' does not match');
  assert(%size(string_t) = %size(  string)    :
         'Size of ''string'' does not match'  );

  //  Trim input string
  string = %trim(i_string);

  //  Remove preceding quotes
  if (%len(string) > 0);
    if ((%subst(string: 1: 1) = Qs) or
        (%subst(string: 1: 1) = Qd));
      string = %subst(string: 2: %len(string) - 1);
    endif;
  endif;

  //  Remove trailing quotes
  if (%len(string) > 0);
    if ((%subst(string: %len(string): 1) = Qs) or
        (%subst(string: %len(string): 1) = Qd));
      string = %subst(string: 1: %len(string) - 1);
    endif;
  endif;

  return string;

end-proc;
//---------------------------------------------------------------------------------------
// Define function prototype to replace double quotes by quotes
//---------------------------------------------------------------------------------------
dcl-proc rmvDblQuotes export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_string varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s string varchar(2000) inz;

  dcl-s x int(10) inz;

  //  quotes
  dcl-c Qs '''';
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(i_string)    :
         'Size of ''i_string'' does not match');
  assert(%size(string_t) = %size(  string)    :
         'Size of ''string'' does not match'  );

  //  Trim input string
  string = %trim(i_string);

  //  Spin through the string and change dbl quotes to quotes
  for x = 1 to %len(string) - 1;
    if (%subst(string: x: 2) = Qs + Qs);
      %subst(string: x) = %subst(string: x+1) + ' ';
    endif;
  endfor;

  return string;

end-proc;
//---------------------------------------------------------------------------------------
//  Replace all occurences of a token in a string
//---------------------------------------------------------------------------------------
dcl-proc replace export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_token  varchar(2000) value; // like(string_t)
    i_string varchar(2000) value; // like(string_t)
    i_value  varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s string varchar(2000) inz; // like(string_t)

  //  local fields
  dcl-s cc int(10) inz;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(i_token )    :
         'Size of ''i_token'' does not match' );
  assert(%size(string_t) = %size(i_string)    :
         'Size of ''i_string'' does not match');
  assert(%size(string_t) = %size(i_value )    :
         'Size of ''i_value'' does not match' );
  assert(%size(string_t) = %size(  string)    :
         'Size of ''string'' does not match'  );

  string = i_string;

  cc=%scan(i_token: string);
  dow (cc>0);
    string=%replace(i_value       :
                    string        :
                    cc            :
                    %len(i_token) );
    cc=%scan(i_token: string: cc+1);
  enddo;

  return string;

end-proc;
//---------------------------------------------------------------------------------------
//  TEst, whether a given string starts with a given prefix.
//---------------------------------------------------------------------------------------
dcl-proc startsWith export;
  dcl-pi *n ind;
    i_prefix varchar(2000) value; // like(string_t)
    i_string varchar(2000) value; // like(string_t)
  end-pi;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (%len(i_string) = 0  or
      %len(i_prefix) = 0  or
      %len(i_string) < %len(i_prefix));
    return *off;
  endif;
  if (%subst(i_string: 1
             : %len(i_prefix)) <> i_prefix);
    return *off;
  endif;

  return *on;

end-proc;
//---------------------------------------------------------------------------------------
//  Format a CL Command.
//---------------------------------------------------------------------------------------
dcl-proc fmtClCmd export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_cmd varchar(2000) value; // like(string_t)
  end-pi;

  //  QCAPCMD API
  dcl-s cmd char(2000) inz; // like(string_t)
  dcl-s cmdLen int(10) inz(%len(cmd));
  dcl-ds optCtrl;
    typCmdPrc  int(10) pos(1) inz(4); // cl commands
    DBCS_Data  char(1) pos(5) inz('1'); // handle DBCS
    prmt_Act   char(1) pos(6) inz('0'); // never prompt
    cmdStrSntx char(1) pos(7) inz('0'); // AS/400 Syntax
    msgRtvKey  char(4) pos(8) inz(*blanks); // no retrieve ke
    res_01     char(9) pos(12) inz(*allx'00');
  end-ds;
  dcl-s optCtrlLen int(10) inz(%len(OptCtrl));
  dcl-s optCtrlFmt char(8) inz('CPOP0100');
  dcl-s retCmd char(2000) inz;
  dcl-s retCmdLenAvl int(10) inz(%len(retCmd));
  dcl-s retCmdLenRtn int(10) inz;

  //  API error code
  dcl-ds errCode;
    errCode_bytPrv   int(10) inz(%size(errCode));
    errCode_bytAvl   int(10) inz;
    errCode_excID    char(7) inz;
    errCode_reserved char(1) inz;
    errCode_escData  char(256) inz;
  end-ds;

  //  QCAPCMD prototype
  dcl-pr QCAPCMD extpgm('QCAPCMD');
    io_cmd          like(cmd);
    io_cmdLen       like(cmdLen);
    io_optCtrl      like(optCtrl);
    io_optCtrlLen   like(optCtrlLen);
    io_optCtrlFmt   like(optCtrlFmt);
    io_retCmd       like(retCmd);
    io_retCmdLenAvl like(retCmdLenAvl);
    io_retCmdLenRtn like(retCmdLenRtn);
    io_errCode      like(errCode);
  end-pr;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(i_cmd   )    :
         'Size of ''i_cmd'' does not match'   );
  assert(%size(string_t) = %size(  cmd   ) +2 :
         'Size of ''cmd'' does not match'     );
  assert(%size(string_t) = %size(  retCmd) +2 :
         'Size of ''retCmd'' does not match'  );

  clear errCode;

  cmd          = i_cmd;

  QCAPCMD(cmd: cmdLen: optCtrl: optCtrlLen: optCtrlFmt:
          retCmd: retCmdLenAvl: retCmdLenRtn: errCode);

  //  Check for errors ...
  if (errCode_bytAvl <> 0);
    retCmd = '';
  else;

    //  Check length of command returned ...
    if (retCmdLenRtn > retCmdLenAvl);
      retCmd = '';
    endif;
  endif;

  return %trimr(retCmd);

end-proc;
//---------------------------------------------------------------------------------------------
//  Remove Remarks from CL String
//---------------------------------------------------------------------------------------------
dcl-proc rmvClRem export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_clCmd varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s retClCmd varchar(2000) inz; // like(string_t)

  //  local fields
  dcl-s isClRem ind inz(*off);
  dcl-s isLiteral ind inz(*off);
  dcl-s x int(10) inz;

  //  local constants
  dcl-c cBegClRem '/*';
  dcl-c cLenBegClRem 2;
  dcl-c cEndClRem '*/';
  dcl-c cLenEndClRem 2;

  dcl-c cBegLit '''';
  dcl-c cLenBegLit 1;
  dcl-c cEndLit '''';
  dcl-c cLenEndLit 1;
  //-------------------------------------------------------------------*

  assert(%size(string_t) = %size(i_clCmd   )  :
         'Size of ''i_clCmd'' does not match' );
  assert(%size(string_t) = %size(  retclCmd)  :
         'Size of ''retClCmd'' does not match');

  x = 1;
  retclCmd = %trim(i_clCmd);

  dow (x < %len(retclCmd));

    //  When we are not yet inside a comment ...
    if (not isClRem);
      //  ... then
      //      check for the start of a literal
      if (not isLiteral and
          %subst(retclCmd: x: cLenBegLit) = cBegLit);
        isLiteral = *on;
        x = x + cLenBegLit;
        iter;
      endif;

      //      check for the end of a literal
      if (isLiteral and
          %subst(retclCmd: x: cLenEndLit) = cEndLit);
        isLiteral = *off;
        x = x + cLenEndLit;
        iter;
      endif;
    endif;

    //  When we are not yet inside a literal ...
    if (not isLiteral);
      //  ... then
      //      check for the start of a comment
      if (%subst(retclCmd: x: cLenBegClRem)= cBegClRem);
        if ((x = 1) or
            (%subst(retclCmd: x - 1: 1) = ' '));
          isClRem = *on;
          %subst(retclCmd: x: cLenBegClRem) = '';
          x = x + cLenBegClRem;
          iter;
        endif;
      endif;

      //      check for the end of a comment
      if (%subst(retclCmd: x: cLenEndClRem)= cEndClRem);
        if ((x = %len(retclCmd) - cLenEndClRem + 1) or
            (%subst(retclCmd: x + cLenEndClRem: 1) = ' '));
          isClRem = *off;
          %subst(retclCmd: x: cLenEndClRem) = '';
          x = x + cLenEndClRem;
          iter;
        endif;
      endif;
    endif;

    //  ... do not copy comments
    if (isClRem);
      %subst(retclCmd: x: 1) = '';
    endif;

    x = x + 1;
  enddo;

  return %trim(retclCmd);

end-proc;
//---------------------------------------------------------------------------------------------
//  Get Keyword Data from String
//---------------------------------------------------------------------------------------------
dcl-proc getKwdData export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_keyWord char(10) value;
    i_string  varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s kwdData varchar(2000) inz; // like(string_t)

  //  local fields
  dcl-s lenKeyWord int(10) inz;
  dcl-s aa int(10) inz;
  dcl-s cc int(10) inz;
  dcl-s numBracket int(10) inz;
  //-------------------------------------------------------------------*

  assert(%size(string_t) = %size(i_string )   :
         'Size of ''i_string'' does not match');
  assert(%size(string_t) = %size(  kwdData)   :
         'Size of ''kwdData'' does not match' );

  //  find the keyword
  i_keyWord = %trim(i_keyWord) + '(';

  aa        = %scan(%trim(i_keyWord): i_string);

  if (aa = 0);
    kwdData = '';
  else;

    aa        = aa + %len(%trim(i_keyWord));
    cc        = aa;
    numBracket= 1;

    //  loop through the string until the closing braket
    dou (cc >= %len(i_string));
      if (%subst(i_string:cc:1) = '(');
        numBracket = numBracket + 1;
        if (numBracket = 1);
          aa=cc + 1;
        endif;
      endif;

      if (%subst(i_string:cc:1) = ')');
        numBracket = numBracket - 1;
        if (numBracket = 0);
          leave;
        endif;
      endif;

      cc = cc + 1;
    enddo;

    //  return the data between the brakets
    kwdData = %subst(i_string: aa: cc-aa);
  endif;

  return kwdData;

end-proc;
//---------------------------------------------------------------------------------------------
//  Get Field Name from String
//---------------------------------------------------------------------------------------------
dcl-proc getFldName export;
  dcl-pi *n varchar(10); // like(string_t)
    i_keyWord char(10) value;
    i_string  varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s fldName varchar(10) inz; // like(string_t)

  //  local fields
  dcl-s tmpFldName varchar(11) inz;
  //-------------------------------------------------------------------*

  assert(%size(string_t) = %size(i_string )   :
         'Size of ''i_string'' does not match');

  //  get keyword value
  tmpFldName = getKwdData(i_keyword: i_string);
  if (tmpFldName = '');
    return '';
  endif;
  //  remove leading '&'
  assert(%subst(tmpFldName: 1: 1) = '&'       :
         'Field name must start with ''&'''   );
  assert(%len(tmpFldName) > 1                 :
         'Field name must not be empty'       );

  fldName = %subst(tmpFldName: 2);

  return fldName;

end-proc;
//---------------------------------------------------------------------------------------------
//  Get Attribute Data from String
//---------------------------------------------------------------------------------------------
dcl-proc getAttrData export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_attr   char(10) value;
    i_string varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s attrData varchar(2000) inz; // like(string_t)

  //  local fields
  dcl-s attr char(20) inz;
  dcl-s lenAttr int(10) inz;
  dcl-s aa int(10) inz;
  dcl-s cc int(10) inz;

  dcl-c Qd '"';
  //-------------------------------------------------------------------*

  assert(%size(string_t) = %size(i_string )   :
         'Size of ''i_string'' does not match');
  assert(%size(string_t) = %size(  attrData)  :
         'Size of ''AttrData'' does not match');

  //  find the keyword
  attr = %trim(i_attr) + '=' + Qd;

  aa   = %scan(attr: i_string) + %len(attr);
  cc   = %scan(Qd: i_string: aa+1);

  //  return the data between the double-quotes
  if ((cc-aa) > 0);
    attrData = %subst(i_string: aa: cc-aa);
  endif;

  return attrData;

end-proc;
//---------------------------------------------------------------------------------------
//  Check for object
//---------------------------------------------------------------------------------------
dcl-proc chkobj export;
  dcl-pi *n ind;
    i_obj  char(10) value;
    i_lib  char(10) value;
    i_type char(10) value;
    i_mbr  char(10) options(*nopass) value;
  end-pi;

  //  parameter positions
  dcl-c p_mbr 4;

  //  return value
  dcl-s isAvailable ind inz(*off);

  //  optional parameter fields
  dcl-s mbr like(i_mbr);

  //  local fields
  dcl-s isPresent int(10) inz;
  //-------------------------------------------------------------------*

  //  check for optional parameters
  if (%parms >= p_mbr);
    isPresent = 1;
  else;
    isPresent = 0;
  endif;

  if (isPresent = 1);
    mbr = i_mbr;
  else;
    mbr = '*NONE';
  endif;

  //  check for object
  if (system('CHKOBJ'
          + ' OBJ('
          + %trim(i_lib)
          + '/'
          + %trim(i_obj)
          + ')'
          + ' OBJTYPE('
          + %trim(i_type)
          + ')'
          + ' MBR('
          + %trim(mbr)
          + ')') = 0);
    isAvailable = *on;
  else;
    isAvailable = *off;
  endif;

  return isAvailable;

end-proc;
//---------------------------------------------------------------------------------------
//  Send Message
//---------------------------------------------------------------------------------------
dcl-proc sndMessage export;
  dcl-pi *n;
    i_msgID   char(7) value;
    i_msgText varchar(512) value;
    i_msgType char(10) value;
    i_msgFile char(10) options(*nopass) value;
    i_msgLib  char(10) options(*nopass) value;
  end-pi;

  //  parameter positions
  dcl-c p_msgFile 4;
  dcl-c p_msgLib 5;

  //  optional parameter fields
  dcl-s msgFile like(i_msgFile) inz;
  dcl-s msgLib like(i_msgLib) inz;

  //  local fields
  dcl-s isPresent int(10) inz;

  //  ... API error code
  dcl-ds errCode;
    errCode_bytPrv   int(10) inz(%size(errCode));
    errCode_bytAvl   int(10) inz;
    errCode_excID    char(7) inz;
    errCode_reserved char(1) inz;
    errCode_excData  char(256) inz;
  end-ds;

  //  ... qualified message file name
  dcl-ds qMsgF;
    qMsgF_name char(10) inz;
    qMsgF_lib  char(10) inz;
  end-ds;

  //  QMHSNDPM prototype
  dcl-pr qmhsndpm extpgm('QMHSNDPM');
    i_msgID       char(7) const;
    i_qMsgF       char(20) const;
    i_msgText     char(32767) options(*varsize) const;
    i_lenMsgText  int(10) const;
    i_msgType     char(10) const;
    i_stackEntry  char(10) const;
    i_stackCountr int(10) const;
    i_msgKey      char(4) const;
    io_errCode    char(32767) options(*varsize);
  end-pr;
  //-------------------------------------------------------------------*

  //  check for optional parameters ...
  //  ... message file
  if (%parms >= p_msgFile);
    isPresent = 1;
  else;
    isPresent = 0;
  endif;

  if (isPresent = 1);
    msgFile = i_msgFile;
  else;
    msgFile = 'QCPFMSG';
  endif;
  //  ... message lib
  if (%parms >= p_msgLib);
    isPresent = 1;
  else;
    isPresent = 0;
  endif;

  if (isPresent = 1);
    msgLib  = i_msgLib;
  else;
    msgLib  = '*LIBL';
  endif;

  //  send message
  qMsgF_name = msgFile;
  qMsgF_lib  = msgLib;

  qmHSNDPM(i_msgID          :
           qMsgF            :
           i_msgText        :
           %size(i_msgText) :
           i_msgType        :
           '*CTLBDY'        :
           1                :
           '    '           :
           errCode          );

  return;

end-proc;
//---------------------------------------------------------------------------------------
//  Assert (similar to the C assert macro)
//---------------------------------------------------------------------------------------
dcl-proc assert export;
  dcl-pi *n;
    i_condition ind value;
    i_text      char(128) value;
    i_procedure char(128) options(*nopass) value;
  end-pi;

  //  parameter positions
  dcl-c p_procedure 3;

  //  optional parameter fields
  dcl-s procedure varchar(128) inz;

  //  local fields
  dcl-s text varchar(512) inz;
  //-------------------------------------------------------------------*

  if (%parms >= p_procedure);
    procedure = %trim(i_procedure);
  else;
    procedure = '*N';
  endif;

  text = procedure + ': ' + %trim(i_text);

  if (not i_condition);
    sndMessage('CPF9898' :
               text      :
               '*ESCAPE' );
  endif;

  return;

end-proc;
//---------------------------------------------------------------------------------------
//  Ensure string length
//---------------------------------------------------------------------------------------
//  This is just a dummy procedure to ensure that string_t is of the same
//  size in every module that calls the procedure "ensureStringLength".
//---------------------------------------------------------------------------------------
dcl-proc ensureStringLength export;
  dcl-pi *n;
    i_size int(10) value;
  end-pi;
  //-------------------------------------------------------------------*

  assert(%size(string_t) = i_size            :
        'Size of ''string_t'' does not match');

  return;

end-proc;
//---------------------------------------------------------------------------------------
//  Convert to upper case
//---------------------------------------------------------------------------------------
dcl-proc uCase export;
  dcl-pi *n varchar(2000); // like(string_t)
    i_string varchar(2000) value; // like(string_t)
  end-pi;

  //  return value
  dcl-s string varchar(2000) inz; // like(string_t)

  //  local fields
  dcl-s lowStr char(2000) inz;
  dcl-s highStr char(2000) inz;
  dcl-s len int(10) inz;

  //  upper / lower case constants
  dcl-c lc 'abcdefghijklmnopqrstuvwxyz';
  dcl-c uc 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  assert(%size(string_t) = %size(i_string )   :
         'Size of ''i_string'' does not match');
  assert(%size(string_t) = %size(  string )   :
         'Size of ''string'' does not match'  );

  len = %len(i_string);

  if (len > 0);
    lowStr = i_string;
    highStr = %xlate(lc: uc: lowStr);
    string = %subst(highStr: 1: len);
  else;
    string = '';
  endif;

  return string;

end-proc;
//---------------------------------------------------------------------------------------
//  Get member text.
//---------------------------------------------------------------------------------------
dcl-proc getMbrTxt export;
  dcl-pi *n char(50);
    i_file char(10) value;
    i_lib  char(10) value;
    i_mbr  char(10) value;
  end-pi;

  //  return value
  dcl-s text char(50) inz;

  //  local fields
  dcl-ds errCode;
    errCode_bytPrv   int(10) inz(%size(errCode));
    errCode_bytAvl   int(10) inz;
    errCode_excID    char(7) inz;
    errCode_reserved char(1) inz;
    errCode_escData  char(256) inz;
  end-ds;

  dcl-ds mbrd0100;
    mbrd0100_bytPrv    int(10) pos(1) inz;
    mbrd0100_bytAvl    int(10) pos(5) inz;
    mbrd0100_file      char(10) pos(9) inz;
    mbrd0100_lib       char(10) pos(19) inz;
    mbrd0100_mbr       char(10) pos(29) inz;
    mbrd0100_attr      char(10) pos(39) inz;
    mbrd0100_srcType   char(10) pos(49) inz;
    mbrd0100_crtDatTim char(13) pos(59) inz;
    mbrd0100_chgDatTim char(13) pos(72) inz;
    mbrd0100_text      char(50) pos(85) inz;
    mbrd0100_srcF      char(1) pos(135) inz;
  end-ds;

  dcl-ds qFile;
    qFile_name char(10) inz;
    qFile_lib  char(10) inz;
  end-ds;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  qFile_name = i_file;
  qFile_lib  = i_lib;

  reset errCode;

  QUSRMBRD(MBRD0100        :
           %size(MBRD0100) :
           'MBRD0100'      :
           qFile           :
           i_mbr           :
           '0'             :
           errCode         );

  if (errCode_bytAvl = 0);
    text = mbrd0100_text;
    text = %xlate('''': ' ': text);  // drop single quotes
    text = %xlate('"': ' ': text);  // drop double quotes
    text = %xlate('<': ' ': text);  // drop less than
    text = %xlate('&': ' ': text);  // drop and
  else;
    text = '';
  endif;

  return text;

end-proc;

//---------------------------------------------------------------------------------------
//  Retrieves version information from the specified source member
//---------------------------------------------------------------------------------------
dcl-proc getVersionInfo export;
  dcl-pi *n varchar(15);
    i_file char(10) value;
    i_lib  char(10) value;
    i_mbr  char(10) value;
  end-pi;

  //  return value
  dcl-s versionInfo varchar(15) inz;

  dcl-s line varchar(240) inz;

  dcl-c cEOF *on;

  dcl-s PATTERN varchar(38) inz('(V[0-9]*\.[0-9]*(\.[0-9]*){0,1})');
  dcl-ds hRegex likeds(regex_t) inz;
  dcl-ds regMatch qualified;
    item likeds(regmatch_t) dim(2) inz;
  end-ds;
  dcl-s nMatch uns(10) inz;
  dcl-s rc int(10) inz;
  dcl-s x int(10) inz;
  dcl-s len int(10) inz;
  dcl-s buf char(256) inz;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (openMbr(i_file: i_lib : i_mbr));

    if (regcomp(hRegex: PATTERN
                : REG_EXTENDED + REG_ICASE) = 0);

      dow (readMbr(line) <> cEOF);
        nMatch = %elem(regmatch.item);
        rc = regexec(hRegex: line
                     : nMatch: regMatch: 0);
        if (rc = 0);
          x = 2;
          if (regMatch.item(x).rm_so <> -1);
            len = regMatch.item(x).rm_eo -
                  regMatch.item(x).rm_so;
            regMatch.item(x).rm_so =
               regMatch.item(x).rm_so + 1;
            versionInfo =
               %subst(line: regMatch.item(x).rm_so: len);
            leave;
          endif;
        else;
          regerror(rc: hRegex: %addr(buf): 256);
        endif;
      enddo;

      regfree(hRegex);
    endif;

    closeMbr();
  endif;

  return versionInfo;

end-proc;

