      *%METADATA                                                       *
      * %TEXT XMLGENRV + XMLGENR service module                        *
      *%EMETADATA                                                      *
     H NOMAIN BNDDIR('QC2LE')
      *---------------------------------------------------------------------------------------------
      * xmlgenrs - XMLGENRV + XMLGENR service module
      * Copyright (C) 01/20/2002  Thomas Raddatz   <thomas.raddatz@tools400.de>
      *
      * This program is free software, you can redistribute it and/or modify it under the terms
      * of the GNU General Public License as published by the Free Software Foundation.
      *--------------------------------------------------------------------------------------------
      * >>PRE-COMPILER<<
      *   >>CRTCMD<< CRTRPGMOD    MODULE(&LI/&OB) +
      *                           SRCFILE(&SL/&SF) SRCMBR(&SM);
      *   >>COMPILE<<
      *     >>PARM<< TRUNCNBR(*NO);
      *     >>PARM<< DBGVIEW(*LIST);
      *     >>PARM<< OPTION(*EVENTF);
      *     >>PARM<< TGTRLS(V6R1M0);
      *   >>END-COMPILE<<
      *   >>EXECUTE<<
      * >>END-PRE-COMPILER<<
      *--------------------------------------------------------------------------------------------
      /copy 'qxmlgen/copyright.rpgleinc'
      *
      *---------------------------------------------------------------------------------------------
      *
      * Provide the following common used procedures:
      *
      *---------------------------------------------------------------------------------------------
     Fscript    if   f  252        disk    usropn                               script file
     F                                     infds(script_)
     Fxml       uf a f  252        disk    usropn                               xml file
     F                                     infds(xml_   )
     Fmbr       if   f  252        disk    usropn                               member
     F                                     infds(mbr_   )
      *
      *  script IO buffer
     D iScript         ds
     D  iScriptSrcSeq          1      6S 2
     D  iScriptSrcDat          7     12S 0
     D  iScriptSrcDta         13    252A
      *
      *  script file information data structure
     D script_         ds
     D script_open             9      9A
     D script_status          11     15S 0
     D script_file            83     92A
     D script_library         93    102A
     D script_rcdLen         125    126I 0
     D script_member         129    138A
     D script_ccsid          218    219I 0
     D script_rcdNbr         397    400I 0
      *
      *  XML IO buffer
     D iXML            ds
     D  iXMLSrcSeq             1      6S 2
     D  iXMLSrcDat             7     12S 0
     D  iXMLSrcDta            13    252A
      *
      *  XML file information data structure
     D XML_            ds
     D XML_open                9      9A
     D XML_status             11     15S 0
     D XML_file               83     92A
     D XML_library            93    102A
     D XML_rcdLen            125    126I 0
     D XML_member            129    138A
     D XML_ccsid             218    219I 0
     D XML_rcdNbr            397    400I 0
      *
      *  mbr IO buffer
     D iMbr            ds
     D  iMbrSrcSeq             1      6S 2
     D  iMbrSrcDat             7     12S 0
     D  iMbrSrcDta            13    252A
      *
      *  mbr file information data structure
     D mbr_            ds
     D mbr_open                9      9A
     D mbr_status             11     15S 0
     D mbr_file               83     92A
     D mbr_library            93    102A
     D mbr_rcdLen            125    126I 0
     D mbr_member            129    138A
     D mbr_ccsid             218    219U 0
     D mbr_rcdNbr            397    400I 0
      *
      *---------------------------------------------------------------------------------------
      *  Exported prototypes:
      *---------------------------------------------------------------------------------------
      /copy 'qxmlgen/xmlgenrs_h.rpgleinc'
      *
      *---------------------------------------------------------------------------------------
      *  Imported procedures and functions:
      *---------------------------------------------------------------------------------------
      *
      /copy 'qxmlgen/regex.rpgleinc'
      *
      * Define function prototype to test for omitted arguments
     D ceetsta         PR                  extproc('CEETSTA')
     D  o_isPresent                  10I 0
     D  i_ArgNumber                  10I 0 const
     D  o_fc                         12A   options(*omit)
      *
      * Define function prototype execute cl commands
     D system...
     D                 PR            10I 0 extproc('system')
     D  i_cmd                          *   value options(*string)
      *
     D EXCP_MSGID      S              7A   import('_EXCP_MSGID')
      *
      * Define function prototype to retrieve member description
     D qusrmbrd        PR                  ExtPgm('QUSRMBRD')
     D  o_rcvVar                  32767a          options(*varsize)
     D  i_lenRcvVar                  10i 0 const
     D  i_format                      8a   const
     D  i_qFile                      20a   const
     D  i_mbr                        10a
     D  i_override                    1a   const
     D  io_errCode                32767a          options(*varsize)
      *
      *---------------------------------------------------------------------------------------
      *  Global fields
      *---------------------------------------------------------------------------------------
     D g_XMLMode       S             10a          inz('*N')
     D g_XMLSrcSeq     S             10i 0        inz
      *
      *---------------------------------------------------------------------------------------
      *  Open script file
      *---------------------------------------------------------------------------------------
     P openScript...
     P                 B                   export
     D                 PI              n
     D  i_file                       10a   value
     D  i_lib                        10a   value
     D  i_mbr                        10a   value
      *
      *  return value
     D isOpen          S               N   inz(*off)
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   if        not chkobj(i_lib: '*LIBL': '*LIB')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Library ' +
     C                                         %trim(i_lib) +
     C                                        ' was not found'       :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   if        not chkobj(i_file: i_lib: '*FILE')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Source File ' +
     C                                         %trim(i_file) +
     C                                        ' was not found in ' +
     C                                         %trim(i_lib)          :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   if        not chkobj(i_file: i_lib: '*FILE': i_mbr)
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Member ' +
     C                                         %trim(i_mbr) +
     C                                        ' was not found in ' +
     C                                         %trim(i_lib) + '/' +
     C                                         %trim(i_file)         :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   callp     system(
     C                             'OVRDBF FILE(' +
     C                                         'SCRIPT' +
     C                                     ') ' +
     C                                     'TOFILE(' +
     C                                         %trimr(i_lib ) + '/' +
     C                                         %trimr(i_file) +
     C                                     ') ' +
     C                                     'MBR(' +
     C                                         %trim(i_mbr) +
     C                                     ') ' +
     C                                     'OVRSCOPE(' +
     C                                         '*CALLLVL' +
     C                                     ') '
     C                                   )
     C                   open      script                                      OPEN MEMBER
      *
     C                   eval      isOpen = *on
      *
     C     exitFnc       tag
      *
     C                   return    isOpen
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Setll in script file
      *---------------------------------------------------------------------------------------
     P setllScript...
     P                 B                   export
     D                 PI
     D  i_rcdNbr                     10i 0 value
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C     i_rcdNbr      setll     script
      *
     C                   return
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Read from script file
      *---------------------------------------------------------------------------------------
     P readScript...
     P                 B                   export
     D                 PI              n
     D  o_line                      240a          varying
      *
      *  return value
     D isEOF           S               n   inz
      *
      *  local fields
     D dataLen         S             10i 0 inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   eval      dataLen = script_rcdLen
     C                                     - %size(iScriptSrcSeq)
     C                                     - %size(iScriptSrcDat)
      *
     C                   read      script        iScript
     C                   if        %eof(script)
     C                   eval      o_line = ''
     C                   eval      isEOF  = *on
     C                   else
     C                   eval      o_line = %subst(iScriptSrcDta :
     C                                             1             :
     C                                             dataLen       )
     C                   eval      isEOF  = *off
     C                   endif
      *
     C                   return    isEOF
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Read a multi-line string from script file
      *---------------------------------------------------------------------------------------
     P loadScriptString...
     P                 B                   export
     D                 PI          2000A         varying                        like(string_t)
     D  i_line                      240a   value varying
      *
      *  return value
     D string          S           2000A   varying  inz
      *
      *  local fields
     D allLoadedFlg    S               N   inz
     D cc              S             10I 0 inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(string)     :
     C                                    'Size of ''string'' does not match' )
      *
     C                   clear                   string
     C                   eval      allLoadedFlg=*off
      *
     C                   dou       allLoadedFlg=*on
     C                   for       cc=%len(i_line) downto 1
      *
     C                   if        %subst(i_line:cc:1) >' '
     C                   if        %subst(i_line:cc:1) ='+'
     C                   eval      %subst(i_line:cc:1) =' '
     C                   else
     C                   eval      allLoadedFlg=*on
     C                   endif
     C                   leave
     C                   endif
      *
     C                   endfor
      *
     C                   eval      string = string +
     C                             %trim(i_line) + ' '
      *
     C                   if        allLoadedFlg=*off
     C                   if        readScript(i_line) = *on
     C                   eval      allLoadedFlg=*on
     C                   endif
     C                   endif
     C                   enddo
      *
     C                   return    %trimr(string)
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Close script file
      *---------------------------------------------------------------------------------------
     P closeScript...
     P                 B                   export
     D                 PI
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   close     script                                      CLOSE MEMBER
      *
     C                   return
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Open XML file
      *---------------------------------------------------------------------------------------
     P openXML...
     P                 B                   export
     D                 PI              n
     D  i_file                       10a   value
     D  i_lib                        10a   value
     D  i_mbr                        10a   value
     D  i_mode                       10a   value
      *
      *  return value
     D isOpen          S               N   inz(*off)
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(i_mode = '*WRITE' or i_mode = '*READ':
     C                             'Mode ' + i_mode + ' not valid for file XML')
      *
     C                   if        not chkobj(i_lib: '*LIBL': '*LIB')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Library ' +
     C                                         %trim(i_lib) +
     C                                        ' was not found'       :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   if        not chkobj(i_file: i_lib: '*FILE')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Source File ' +
     C                                         %trim(i_file) +
     C                                        ' was not found in ' +
     C                                         %trim(i_lib)          :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   if        not chkobj(i_file: i_lib: '*FILE': i_mbr)
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Member ' +
     C                                         %trim(i_mbr) +
     C                                        ' was not found in ' +
     C                                         %trim(i_lib) + '/' +
     C                                         %trim(i_file)         :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   callp     system(
     C                             'OVRDBF FILE(' +
     C                                         'XML' +
     C                                     ') ' +
     C                                     'TOFILE(' +
     C                                         %trimr(i_lib ) + '/' +
     C                                         %trimr(i_file) +
     C                                     ') ' +
     C                                     'MBR(' +
     C                                         %trim(i_mbr) +
     C                                     ') ' +
     C                                     'OVRSCOPE(' +
     C                                         '*CALLLVL' +
     C                                     ') '
     C                                   )
     C                   open      xml                                         OPEN MEMBER
      *
     C                   eval      g_XMLMode   = i_mode
     C                   eval      g_XMLSrcSeq = 0
      *
     C                   eval      isOpen      = *on
      *
     C     exitFnc       tag
      *
     C                   eval      iXMLSrcSeq = 0
      *
     C                   return    isOpen
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Read from XML file
      *---------------------------------------------------------------------------------------
     P readXML...
     P                 B                   export
     D                 PI              n
     D  o_line                      240a          varying
      *
      *  return value
     D isEOF           S               n   inz
      *
      *  local fields
     D dataLen         S             10i 0 inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(g_XMLMode = '*READ'                 :
     C                             'File XML not opened for *READ operations' )
      *
     C                   eval      dataLen = xml_rcdLen
     C                                     - %size(iXMLSrcSeq)
     C                                     - %size(iXMLSrcDat)
      *
     C                   read      XML           iXML
     C                   if        %eof(XML)
     C                   eval      o_line = ''
     C                   eval      isEOF  = *on
     C                   else
     C                   eval      o_line = %subst(iXMLSrcDta :
     C                                             1          :
     C                                             dataLen    )
     C                   eval      isEOF  = *off
     C                   endif
      *
     C                   return    isEOF
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Write to XML file
      *---------------------------------------------------------------------------------------
     P writeXML...
     P                 B                   export
     D                 PI
     D  i_line                      240a   value  varying
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(g_XMLMode = '*WRITE'                :
     C                             'File XML not opened for *WRITE operations')
      *
     C                   eval      g_XMLSrcSeq = g_XMLSrcSeq + .01
      *
     C                   eval      iXMLSrcSeq = g_XMLSrcSeq
     C                   eval      iXMLSrcDat = 0
     C                   eval      iXMLSrcDta = i_line
      *
     C                   write     XML           iXML
      *
     C                   return
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Write a multi-line string to XML file
      *---------------------------------------------------------------------------------------
     P writeXMLString...
     P                 B                   export
     D                 PI
     D  i_string                   2000A   value varying                        like(string)
      *
      *  local fields
     D start           S             10I 0  inz
     D len             S             10I 0  inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(i_string)    :
     C                                    'Size of ''i_string'' does not match')
      *
     C                   eval      start = 1
      *
     C                   dow       start <= %len(i_string)
      *
     C                   if        (start + 100 - 1) <= %len(i_string)
     C                   eval      len = 100
     C                   else
     C                   eval      len = %len(i_string) - start + 1
     C                   endif
      *
     C                   callp     writeXML(%subst(i_string: start: len))
     C                   eval      start = start + 100
     C                   enddo
      *
     C                   return
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Close XML file
      *---------------------------------------------------------------------------------------
     P closeXML...
     P                 B                   export
     D                 PI
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   close     xml                                         CLOSE MEMBER
      *
     C                   eval      g_XMLMode = '*N'
      *
     C                   return
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Open member file
      *---------------------------------------------------------------------------------------
     P openMbr...
     P                 B                   export
     D                 PI              n
     D  i_file                       10a   value
     D  i_lib                        10a   value
     D  i_mbr                        10a   value
      *
      *  return value
     D isOpen          S               N   inz(*off)
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   if        not chkobj(i_lib: '*LIBL': '*LIB')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Library ' +
     C                                         %trim(i_lib) +
     C                                        ' was not found'       :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   if        not chkobj(i_file: i_lib: '*FILE')
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Source File ' +
     C                                         %trim(i_file) +
     C                                        ' was not found in ' +
     C                                         %trim(i_lib)          :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   if        not chkobj(i_file: i_lib: '*FILE': i_mbr)
     C                   callp     sndMessage('CPF9897'              :
     C                                        '0000 Member ' +
     C                                         %trim(i_mbr) +
     C                                        ' was not found in ' +
     C                                         %trim(i_lib) + '/' +
     C                                         %trim(i_file)         :
     C                                        '*DIAG'                )
     C                   eval      isOpen = *off
     C                   goto      exitFnc
     C                   endif
      *
     C                   callp     system(
     C                             'OVRDBF FILE(' +
     C                                         'MBR' +
     C                                     ') ' +
     C                                     'TOFILE(' +
     C                                         %trimr(i_lib ) + '/' +
     C                                         %trimr(i_file) +
     C                                     ') ' +
     C                                     'MBR(' +
     C                                         %trim(i_mbr) +
     C                                     ') ' +
     C                                     'OVRSCOPE(' +
     C                                         '*CALLLVL' +
     C                                     ') '
     C                                   )
     C                   open      mbr                                         OPEN MEMBER
      *
     C                   eval      isOpen = *on
      *
     C     exitFnc       tag
      *
     C                   return    isOpen
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Read from member file
      *---------------------------------------------------------------------------------------
     P readMbr...
     P                 B                   export
     D                 PI              n
     D  o_line                      240a          varying
      *
      *  return value
     D isEOF           S               N   inz
      *
      *  local fields
     D dataLen         S             10i 0 inz
     D cLOW_           C                   const(
     D                                      x'000102030405060708090A0B0C0D0E0F+
     D                                        101112131415161718191A1B1C1D1E1F+
     D                                        202122232425262728292A2B2C2D2E2F+
     D                                        303132333435363738393A3B3C3D3E3F')
     D cBLANK          C                   const(
     D                                      x'40404040404040404040404040404040+
     D                                        40404040404040404040404040404040+
     D                                        40404040404040404040404040404040+
     D                                        40404040404040404040404040404040')
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   eval      dataLen = mbr_rcdLen
     C                                     - %size(iMbrSrcSeq)
     C                                     - %size(iMbrSrcDat)
      *
     C                   read      mbr           iMbr
     C                   if        %eof(mbr)
     C                   eval      o_line = ''
     C                   eval      isEOF  = *on
     C                   else
     C                   eval      o_line = %subst(iMbrSrcDta :
     C                                             1          :
     C                                             dataLen    )
     C                   eval      o_line = %xlate(cLOW_   : cBLANK: o_line)
     C                   eval      isEOF  = *off
     C                   endif
      *
     C                   return    isEOF
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Close member file
      *---------------------------------------------------------------------------------------
     P closeMbr...
     P                 B                   export
     D                 PI
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   close     mbr                                         CLOSE MEMBER
      *
     C                   return
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Get member CCSID.
      *---------------------------------------------------------------------------------------
     P getMbrCCSID...
     P                 B                   export
     D                 PI             5u 0
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   return    mbr_ccsid
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Get member record length.
      *---------------------------------------------------------------------------------------
     P getMbrRcdLen...
     P                 B                   export
     D                 PI             5i 0
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   return    mbr_rcdLen
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Remove preceding and trailing quotes from a string
      *---------------------------------------------------------------------------------------
     P rmvQuotes...
     P                 B                   export
     D                 PI          2000A         varying                        like(string_t)
     D  i_string                   2000A   value varying                        like(string_t)
      *
      *  return value
     D string          S           2000A   inz   varying
      *
      *  quotes
     D Qs              c                   ''''
     D Qd              c                   '"'
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(i_string)    :
     C                                    'Size of ''i_string'' does not match')
     C                   callp     assert(%size(string_t) = %size(  string)    :
     C                                    'Size of ''string'' does not match'  )
      *
      *  Trim input string
     C                   Eval      string = %trim(i_string)
      *
      *  Remove preceding quotes
     C                   if        %len(string) > 0
     C                   if        (%subst(string: 1: 1) = Qs) or
     C                             (%subst(string: 1: 1) = Qd)
     C                   eval      string = %subst(string: 2: %len(string) - 1)
     C                   endif
     C                   endif
      *
      *  Remove trailing quotes
     C                   if        %len(string) > 0
     C                   if        (%subst(string: %len(string): 1) = Qs) or
     C                             (%subst(string: %len(string): 1) = Qd)
     C                   eval      string = %subst(string: 1: %len(string) - 1)
     C                   endif
     C                   endif
      *
     C                   Return    string
      *
     P                 E
      *---------------------------------------------------------------------------------------
      * Define function prototype to replace double quotes by quotes
      *---------------------------------------------------------------------------------------
     P rmvDblQuotes...
     P                 B                   export
     D                 PI          2000A         varying                        like(string_t)
     D  i_string                   2000A   value varying                        like(string_t)
      *
      *  return value
     D string          S           2000A   inz   varying
      *
     D x               S             10I 0 inz
      *
      *  quotes
     D Qs              c                   ''''
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(i_string)    :
     C                                    'Size of ''i_string'' does not match')
     C                   callp     assert(%size(string_t) = %size(  string)    :
     C                                    'Size of ''string'' does not match'  )
      *
      *  Trim input string
     C                   Eval      string = %trim(i_string)
      *
      *  Spin through the string and change dbl quotes to quotes
     C                   For       x = 1 to %len(string) - 1
     C                   If        %subst(string: x: 2) = Qs + Qs
     C                   Eval      %subst(string: x) = %subst(string: x+1) + ' '
     C                   Endif
     C                   Endfor
      *
     C                   Return    string
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Replace all occurences of a token in a string
      *---------------------------------------------------------------------------------------
     P replace...
     P                 B                   export
     D                 PI          2000A         varying                        like(string_t)
     D  i_token                    2000A   value varying                        like(string_t)
     D  i_string                   2000A   value varying                        like(string_t)
     D  i_value                    2000A   value varying                        like(string_t)
      *
      *  return value
     D string          S           2000A   varying inz                          like(string_t)
      *
      *  local fields
     D cc              S             10I 0 inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(i_token )    :
     C                                    'Size of ''i_token'' does not match' )
     C                   callp     assert(%size(string_t) = %size(i_string)    :
     C                                    'Size of ''i_string'' does not match')
     C                   callp     assert(%size(string_t) = %size(i_value )    :
     C                                    'Size of ''i_value'' does not match' )
     C                   callp     assert(%size(string_t) = %size(  string)    :
     C                                    'Size of ''string'' does not match'  )
      *
     C                   eval      string = i_string
      *
     C                   eval      cc=%scan(i_token: string)
     C                   dow       cc>0
     C                   eval      string=%replace(i_value       :
     C                                             string        :
     C                                             cc            :
     C                                             %len(i_token) )
     C                   eval      cc=%scan(i_token: string: cc+1)
     C                   enddo
      *
     C                   Return    string
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  TEst, whether a given string starts with a given prefix.
      *---------------------------------------------------------------------------------------
     P startsWith...
     P                 B                   export
     D                 PI              N
     D  i_prefix                   2000A   value varying                        like(string_t)
     D  i_string                   2000A   value varying                        like(string_t)
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   if        %len(i_string) = 0  or
     C                             %len(i_prefix) = 0  or
     C                             %len(i_string) < %len(i_prefix)
     C                   return    *OFF
     C                   endif
     C
     C                   if        %subst(i_string: 1
     C                                    : %len(i_prefix)) <> i_prefix
    CC                   return    *OFF
    CC                   endif
      *
     C                   return    *ON
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Format a CL Command.
      *---------------------------------------------------------------------------------------
     P fmtClCmd...
     P                 B                   export
     D                 PI          2000A         varying                        like(string_t)
     D  i_cmd                      2000A   value varying                        like(string_t)
      *
      *  QCAPCMD API
     D cmd             S           2000A   inz                                  like(string_t)
     D cmdLen          S             10i 0 inz(%len(cmd))
     D optCtrl         DS
     D  typCmdPrc              1      4i 0 inz(4)                               cl commands
     D  DBCS_Data              5      5a   inz('1')                             handle DBCS
     D  prmt_Act               6      6a   inz('0')                             never prompt
     D  cmdStrSntx             7      7a   inz('0')                             AS/400 Syntax
     D  msgRtvKey              8     11a   inz(*BLANKS)                         no retrieve ke
     D  res_01                12     20a   inz(*ALLx'00')
     D optCtrlLen      S             10i 0 inz(%len(OptCtrl))
     D optCtrlFmt      S              8a   inz('CPOP0100')
     D retCmd          S           2000A   inz
     D retCmdLenAvl    S             10i 0 inz(%len(retCmd))
     D retCmdLenRtn    S             10i 0 inz
      *
      *  API error code
     D errCode         DS
     D  errCode_bytPrv...
     D                               10i 0 inz(%size(errCode))
     D  errCode_bytAvl...
     D                               10i 0 inz
     D  errCode_excID...
     D                                7a   inz
     D  errCode_reserved...
     D                                1a   inz
     D  errCode_escData...
     D                              256a   inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(i_cmd   )    :
     C                                    'Size of ''i_cmd'' does not match'   )
     C                   callp     assert(%size(string_t) = %size(  cmd   ) +2 :
     C                                    'Size of ''cmd'' does not match'     )
     C                   callp     assert(%size(string_t) = %size(  retCmd) +2 :
     C                                    'Size of ''retCmd'' does not match'  )
      *
     C                   clear                   errCode
      *
     C                   eval      cmd          = i_cmd
      *
     C                   call      'QCAPCMD'
     C                   parm                    cmd
     C                   parm                    cmdLen
     C                   parm                    optCtrl
     C                   parm                    optCtrlLen
     C                   parm                    optCtrlFmt
     C                   parm                    retCmd
     C                   parm                    retCmdLenAvl
     C                   parm                    retCmdLenRtn
     C                   parm                    errCode
      *
      *  Check for errors ...
     C                   if        errCode_bytAvl <> 0
     C                   eval      retCmd = ''
     C                   else
      *
      *  Check length of command returned ...
     C                   if        retCmdLenRtn > retCmdLenAvl
     C                   eval      retCmd = ''
     C                   endif
     C                   endif
      *
     C                   return    %trimr(retCmd)
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Remove Remarks from CL String
      *---------------------------------------------------------------------------------------------
     P rmvClRem...
     P                 B                          export
     D                 PI          2000A          varying                       like(string_t)
     D  i_clCmd                    2000A   value  varying                       like(string_t)
      *
      *  return value
     D retClCmd        S           2000A   varying inz                          like(string_t)
      *
      *  local fields
     D isClRem         S               n   inz(*off)
     D isLiteral       S               n   inz(*off)
     D x               S             10i 0 inz
      *
      *  local constants
     D cBegClRem       C                   const('/*')
     D cLenBegClRem    C                   const(2)
     D cEndClRem       C                   const('*/')
     D cLenEndClRem    C                   const(2)
      *
     D cBegLit         C                   const('''')
     D cLenBegLit      C                   const(1)
     D cEndLit         C                   const('''')
     D cLenEndLit      C                   const(1)
      *-------------------------------------------------------------------*
      *
     C                   callp     assert(%size(string_t) = %size(i_clCmd   )  :
     C                                    'Size of ''i_clCmd'' does not match' )
     C                   callp     assert(%size(string_t) = %size(  retclCmd)  :
     C                                    'Size of ''retClCmd'' does not match')
      *
     C                   Eval      x = 1
     C                   Eval      retclCmd = %trim(i_clCmd)
      *
     C                   DoW       x < %len(retclCmd)
      *
      *  When we are not yet inside a comment ...
     C                   If        not isClRem
      *  ... then
      *      check for the start of a literal
     C                   If        not isLiteral and
     C                             %subst(retclCmd: x: cLenBegLit) = cBegLit
     C                   Eval      isLiteral = *on
     C                   Eval      x = x + cLenBegLit
     C                   Iter
     C                   Endif
      *
      *      check for the end of a literal
     C                   If        isLiteral and
     C                             %subst(retclCmd: x: cLenEndLit) = cEndLit
     C                   Eval      isLiteral = *off
     C                   Eval      x = x + cLenEndLit
     C                   Iter
     C                   Endif
     C                   Endif
      *
      *  When we are not yet inside a literal ...
     C                   If        not isLiteral
      *  ... then
      *      check for the start of a comment
     C                   If        %subst(retclCmd: x: cLenBegClRem)= cBegClRem
     C                   If        (x = 1) or
     C                             (%subst(retclCmd: x - 1: 1) = ' ')
     C                   Eval      isClRem = *on
     C                   Eval      %subst(retclCmd: x: cLenBegClRem) = ''
     C                   Eval      x = x + cLenBegClRem
     C                   Iter
     C                   Endif
     C                   Endif
      *
      *      check for the end of a comment
     C                   If        %subst(retclCmd: x: cLenEndClRem)= cEndClRem
     C                   If        (x = %len(retclCmd) - cLenEndClRem + 1) or
     C                             (%subst(retclCmd: x + cLenEndClRem: 1) = ' ')
     C                   Eval      isClRem = *off
     C                   Eval      %subst(retclCmd: x: cLenEndClRem) = ''
     C                   Eval      x = x + cLenEndClRem
     C                   Iter
     C                   Endif
     C                   Endif
     C                   Endif
      *
      *  ... do not copy comments
     C                   If        isClRem
     C                   Eval      %subst(retclCmd: x: 1) = ''
     C                   Endif
      *
     C                   Eval      x = x + 1
     C                   Enddo
      *
     C                   Return    %trim(retclCmd)
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Get Keyword Data from String
      *---------------------------------------------------------------------------------------------
     P getKwdData...
     P                 B                          export
     D                 PI          2000A          varying                       like(string_t)
     D  i_keyWord                    10a   value
     D  i_string                   2000A   value  varying                       like(string_t)
      *
      *  return value
     D kwdData         S           2000A   varying inz                          like(string_t)
      *
      *  local fields
     D lenKeyWord      S             10i 0 inz
     D aa              S             10i 0 inz
     D cc              S             10i 0 inz
     D numBracket      S             10i 0 inz
      *-------------------------------------------------------------------*
      *
     C                   callp     assert(%size(string_t) = %size(i_string )   :
     C                                    'Size of ''i_string'' does not match')
     C                   callp     assert(%size(string_t) = %size(  kwdData)   :
     C                                    'Size of ''kwdData'' does not match' )
      *
      *  find the keyword
     C                   eval      i_keyWord = %trim(i_keyWord) + '('
      *
     C                   eval      aa        = %scan(%trim(i_keyWord): i_string)
      *
     C                   if        aa = 0
     C                   eval      kwdData = ''
     C                   else
      *
     C                   eval      aa        = aa + %len(%trim(i_keyWord))
     C                   eval      cc        = aa
     C                   eval      numBracket= 1
      *
      *  loop through the string until the closing braket
     C                   dou       cc >= %len(i_string)
     C                   if        %subst(i_string:cc:1) = '('
     C                   eval      numBracket = numBracket + 1
     C                   if        numBracket = 1
     C                   eval      aa=cc + 1
     C                   endif
     C                   endif
      *
     C                   if        %subst(i_string:cc:1) = ')'
     C                   eval      numBracket = numBracket - 1
     C                   if        numBracket = 0
     C                   leave
     C                   endif
     C                   endif
      *
     C                   eval      cc = cc + 1
     C                   Enddo
      *
      *  return the data between the brakets
     C                   eval      kwdData = %subst(i_string: aa: cc-aa)
     C                   endif
      *
     C                   Return    kwdData
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Get Field Name from String
      *---------------------------------------------------------------------------------------------
     P getFldName...
     P                 B                          export
     D                 PI            10a          varying                       like(string_t)
     D  i_keyWord                    10a   value
     D  i_string                   2000a   value  varying                       like(string_t)
      *
      *  return value
     D fldName         S             10a   varying inz                          like(string_t)
      *
      *  local fields
     D tmpFldName      S             11a   varying inz
      *-------------------------------------------------------------------*
      *
     C                   callp     assert(%size(string_t) = %size(i_string )   :
     C                                    'Size of ''i_string'' does not match')
      *
      *  get keyword value
     C                   eval      tmpFldName = getKwdData(i_keyword: i_string)
     C                   if        tmpFldName = ''
     C                   return    ''
     C                   endif
      *  remove leading '&'
     C                   callp     assert(%subst(tmpFldName: 1: 1) = '&'       :
     C                                    'Field name must start with ''&'''   )
     C                   callp     assert(%len(tmpFldName) > 1                 :
     C                                    'Field name must not be empty'       )
      *
     C                   eval      fldName = %subst(tmpFldName: 2)
      *
     C                   Return    fldName
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Get Attribute Data from String
      *---------------------------------------------------------------------------------------------
     P getAttrData...
     P                 B                          export
     D                 PI          2000A          varying                       like(string_t)
     D  i_attr                       10a   value
     D  i_string                   2000A   value  varying                       like(string_t)
      *
      *  return value
     D attrData        S           2000A   varying inz                          like(string_t)
      *
      *  local fields
     D attr            S             20a   inz
     D lenAttr         S             10i 0 inz
     D aa              S             10i 0 inz
     D cc              S             10i 0 inz
      *
     D Qd              C                   const('"')
      *-------------------------------------------------------------------*
      *
     C                   callp     assert(%size(string_t) = %size(i_string )   :
     C                                    'Size of ''i_string'' does not match')
     C                   callp     assert(%size(string_t) = %size(  attrData)  :
     C                                    'Size of ''AttrData'' does not match')
      *
      *  find the keyword
     C                   eval      attr = %trim(i_attr) + '=' + Qd
      *
     C                   eval      aa   = %scan(attr: i_string) + %len(attr)
     C                   eval      cc   = %scan(Qd: i_string: aa+1)
      *
      *  return the data between the double-quotes
     C                   if        (cc-aa) > 0
     C                   eval      attrData = %subst(i_string: aa: cc-aa)
     C                   endif
      *
     C                   Return    attrData
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Check for object
      *---------------------------------------------------------------------------------------
     P chkobj...
     P                 B                          export
     D                 PI              n
     D  i_obj                        10a   value
     D  i_lib                        10a   value
     D  i_type                       10a   value
     D  i_mbr                        10a   value  options(*nopass)
      *
      *  parameter positions
     D p_mbr           C                   const(4)
      *
      *  return value
     D isAvailable     S               N   inz(*off)
      *
      *  optional parameter fields
     D mbr             S                   like(i_mbr)
      *
      *  local fields
     D isPresent       S             10I 0 inz
      *-------------------------------------------------------------------*
      *
      *  check for optional parameters
     C                   if        %parms >= p_mbr
     C                   eval      isPresent = 1
     C                   else
     C                   eval      isPresent = 0
     C                   endif
      *
     C                   if        isPresent = 1
     C                   eval      mbr = i_mbr
     C                   else
     C                   eval      mbr = '*NONE'
     C                   endif
      *
      *  check for object
     C                   if        system('CHKOBJ'
     C                                 + ' OBJ('
     C                                 + %trim(i_lib)
     C                                 + '/'
     C                                 + %trim(i_obj)
     C                                 + ')'
     C                                 + ' OBJTYPE('
     C                                 + %trim(i_type)
     C                                 + ')'
     C                                 + ' MBR('
     C                                 + %trim(mbr)
     C                                 + ')') = 0
     C                   eval      isAvailable = *on
     C                   else
     C                   eval      isAvailable = *off
     C                   endif
      *
     C                   return    isAvailable
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Send Message
      *---------------------------------------------------------------------------------------
     P sndMessage...
     P                 B                          export
     D                 PI
     D  i_msgID                       7a   value
     D  i_msgText                   512a   value  varying
     D  i_msgType                    10a   value
     D  i_msgFile                    10a   value  options(*nopass)
     D  i_msgLib                     10a   value  options(*nopass)
      *
      *  parameter positions
     D p_msgFile       C                   const(4)
     D p_msgLib        C                   const(5)
      *
      *  optional parameter fields
     D msgFile         S                   like(i_msgFile ) inz
     D msgLib          S                   like(i_msgLib  ) inz
      *
      *  local fields
     D isPresent       S             10I 0 inz
      *
      *  ... API error code
     D errCode         DS
     D  errCode_bytPrv...
     D                               10I 0 inz(%size(errCode))
     D  errCode_bytAvl...
     D                               10I 0 inz
     D  errCode_excID...
     D                                7A   inz
     D  errCode_reserved...
     D                                1A   inz
     D  errCode_excData...
     D                              256A   inz
      *
      *  ... qualified message file name
     D qMsgF           DS
     D  qMsgF_name                   10a   inz
     D  qMsgF_lib                    10a   inz
      *
      *  QMHSNDPM prototype
     D qmhsndpm        PR                  ExtPgm('QMHSNDPM')
     D  i_msgID                       7a   const
     D  i_qMsgF                      20a   const
     D  i_msgText                 32767a   const options(*varsize)
     D  i_lenMsgText                 10i 0 const
     D  i_msgType                    10a   const
     D  i_stackEntry                 10a   const
     D  i_stackCountr                10i 0 const
     D  i_msgKey                      4    const
     D  io_errCode                32767a         options(*varsize)
      *-------------------------------------------------------------------*
      *
      *  check for optional parameters ...
      *  ... message file
     C                   if        %parms >= p_msgFile
     C                   eval      isPresent = 1
     C                   else
     C                   eval      isPresent = 0
     C                   endif
      *
     C                   if        isPresent = 1
     C                   eval      msgFile = i_msgFile
     C                   else
     C                   eval      msgFile = 'QCPFMSG'
     C                   endif
      *  ... message lib
     C                   if        %parms >= p_msgLib
     C                   eval      isPresent = 1
     C                   else
     C                   eval      isPresent = 0
     C                   endif
      *
     C                   if        isPresent = 1
     C                   eval      msgLib  = i_msgLib
     C                   else
     C                   eval      msgLib  = '*LIBL'
     C                   endif
      *
      *  send message
     C                   eval      qMsgF_name = msgFile
     C                   eval      qMsgF_lib  = msgLib
      *
     C                   callp     qmHSNDPM(i_msgID          :
     C                                      qMsgF            :
     C                                      i_msgText        :
     C                                      %size(i_msgText) :
     C                                      i_msgType        :
     C                                      '*CTLBDY'        :
     C                                      1                :
     C                                      '    '           :
     C                                      errCode          )
      *
     C                   return
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Assert (similar to the C assert macro)
      *---------------------------------------------------------------------------------------
     P assert...
     P                 B                          export
     D                 PI
     D  i_condition                    n   value
     D  i_text                      128a   value
     D  i_procedure                 128a   value  options(*nopass)
      *
      *  parameter positions
     D p_procedure     C                   const(3)
      *
      *  optional parameter fields
     D procedure       S            128A   varying  inz
      *
      *  local fields
     D text            S            512A   varying  inz
      *-------------------------------------------------------------------*
      *
     C                   If        %parms >= p_procedure
     C                   Eval      procedure = %trim(i_procedure)
     C                   Else
     C                   Eval      procedure = '*N'
     C                   Endif
      *
     C                   Eval      text = procedure + ': ' + %trim(i_text)
      *
     C                   if        not i_condition
     C                   callp     sndMessage('CPF9898' :
     C                                        text      :
     C                                        '*ESCAPE' )
     C                   endif
      *
     C                   return
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Ensure string length
      *---------------------------------------------------------------------------------------
      *  This is just a dummy procedure to ensure that string_t is of the same
      *  size in every module that calls the procedure "ensureStringLength".
      *---------------------------------------------------------------------------------------
     P ensureStringLength...
     P                 B                         export
     D                 PI
     D  i_size                       10i 0 value
      *-------------------------------------------------------------------*
      *
     C                   callp     assert(%size(string_t) = i_size            :
     C                                   'Size of ''string_t'' does not match')
      *
     C                   return
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Convert to upper case
      *---------------------------------------------------------------------------------------
     P uCase...
     P                 B                         export
     D                 PI          2000A         varying                        like(string_t)
     D  i_string                   2000A   value varying                        like(string_t)
      *
      *  return value
     D string          S           2000A   varying inz                          like(string_t)
      *
      *  local fields
     D lowStr          S           2000A   inz
     D highStr         S           2000A   inz
     D len             S             10i 0 inz
      *
      *  upper / lower case constants
     D lc              C                   const('abcdefghijklmnopqrstuvwxyz')
     D uc              C                   CONST('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   callp     assert(%size(string_t) = %size(i_string )   :
     C                                    'Size of ''i_string'' does not match')
     C                   callp     assert(%size(string_t) = %size(  string )   :
     C                                    'Size of ''string'' does not match'  )
      *
     C                   Eval      len = %len(i_string)
      *
     C                   If        len > 0
     C                   Eval      lowStr = i_string
     C     lc:uc         Xlate     lowStr        highStr
     C                   Eval      string = %subst(highStr: 1: len)
     C                   Else
     C                   Eval      string = ''
     C                   Endif
      *
     C                   Return    string
      *
     P                 E
      *---------------------------------------------------------------------------------------
      *  Get member text.
      *---------------------------------------------------------------------------------------
     P getMbrTxt...
     P                 B                         export
     D                 PI            50a
     D  i_file                       10a   value
     D  i_lib                        10a   value
     D  i_mbr                        10a   value
      *
      *  return value
     D text            S             50a   inz
      *
      *  local fields
     D errCode         DS
     D  errCode_bytPrv...
     D                               10i 0 inz(%size(errCode))
     D  errCode_bytAvl...
     D                               10i 0 inz
     D  errCode_excID...
     D                                7a   inz
     D  errCode_reserved...
     D                                1a   inz
     D  errCode_escData...
     D                              256a   inz
      *
     D mbrd0100        DS
     D  mbrd0100_bytPrv...
     D                         1      4i 0 inz
     D  mbrd0100_bytAvl...
     D                         5      8i 0 inz
     D  mbrd0100_file...
     D                         9     18    inz
     D  mbrd0100_lib...
     D                        19     28    inz
     D  mbrd0100_mbr...
     D                        29     38    inz
     D  mbrd0100_attr...
     D                        39     48    inz
     D  mbrd0100_srcType...
     D                        49     58    inz
     D  mbrd0100_crtDatTim...
     D                        59     71    inz
     D  mbrd0100_chgDatTim...
     D                        72     84    inz
     D  mbrd0100_text...
     D                        85    134    inz
     D  mbrd0100_srcF...
     D                       135    135    inz
      *
     D qFile           DS
     D  qFile_name                   10a   inz
     D  qFile_lib                    10a   inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   eval      qFile_name = i_file
     C                   eval      qFile_lib  = i_lib
      *
     C                   reset                   errCode
      *
     C                   callp     QUSRMBRD(MBRD0100        :
     C                                      %size(MBRD0100) :
     C                                      'MBRD0100'      :
     C                                      qFile           :
     C                                      i_mbr           :
     C                                      '0'             :
     C                                      errCode         )
     C
      *
     C                   if        errCode_bytAvl = 0
     C                   eval      text = mbrd0100_text
     C     '''':' '      xlate     text          text                           drop single quotes
     C     '"':' '       xlate     text          text                           drop double quotes
     C     '<':' '       xlate     text          text                           drop less than
     C     '&':' '       xlate     text          text                           drop and
     C                   else
     C                   eval      text = ''
     C                   endif
      *
     C                   Return    text
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------
      *  Retrieves version information from the specified source member
      *---------------------------------------------------------------------------------------
     P getVersionInfo...
     P                 B                         export
     D                 PI            15a   varying
     D  i_file                       10a   value
     D  i_lib                        10a   value
     D  i_mbr                        10a   value
      *
      *  return value
     D versionInfo     S             15a   varying inz
      *
     D line            S            240a   varying inz
      *
     D cEOF            C                   const(*on )
      *
     D PATTERN         S             38A   inz('(V[0-9]*\.[0-9]*+
     D                                     (\.[0-9]*){0,1})') varying
     D hRegex          DS                  likeds(regex_t) inz
     D regMatch        DS                  qualified
     D  item                               likeds(regmatch_t) dim(2) inz
     D nMatch          S             10U 0 inz
     D rc              S             10I 0 inz
     D x               S             10I 0 inz
     D len             S             10I 0 inz
     D buf             S            256a   inz
      * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      *
     C                   if        openMbr(i_file: i_lib : i_mbr)
      *
     C                   if        (regcomp(hRegex: PATTERN
     C                                      : REG_EXTENDED + REG_ICASE) = 0)
      *
     C                   dow       readMbr(line) <> cEOF
     C                   eval      nMatch = %elem(regmatch.item)
     C                   eval      rc = regexec(hRegex: line
     C                                          : nMatch: regMatch: 0)
     C                   if        (rc = 0)
     C                   eval      x = 2
     C                   if        (regMatch.item(x).rm_so <> -1)
     C                   eval      len = regMatch.item(x).rm_eo -
     C                                   regMatch.item(x).rm_so
     C                   eval      regMatch.item(x).rm_so =
     C                                regMatch.item(x).rm_so + 1
     C                   eval      versionInfo =
     C                                %subst(line: regMatch.item(x).rm_so: len)
     C                   leave
     C                   endif
     C                   else
     C                   callp     regerror(rc: hRegex: %addr(buf): 256)
     C                   endif
     C                   enddo
      *
     C                   callp     regfree(hRegex)
     C                   endif
      *
     C                   Callp     closeMbr()
     C                   endif
      *
     C                   Return    versionInfo
      *
     P                 E
      *
