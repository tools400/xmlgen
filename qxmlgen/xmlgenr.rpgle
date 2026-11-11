      *%METADATA                                                       *
      * %TEXT gen xml source file                                      *
      *%EMETADATA                                                      *
      *--------------------------------------------------------------------------------------------
      * XMLGENR - generate XML code for utility uploads.
      * Copyright (C) 6/19/2001  Craig Rutledge    <craig_rutledge@mohawkind.com>
      *
      * This program is free software, you can redistribute it and/or modify it
      * under the terms of the GNU General Public License as published by
      * the Free Software Foundation.  See GNU General Public License for details
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
      *   >>CMD<<    CRTPGM       PGM(&LI/&OB) +
      *                           MODULE(&LI/&OB               +
      *                                  &LI/XMLGENRS     )    +
      *                           ACTGRP(*NEW) +
      *                           TGTRLS(V6R1M0) +
      *                           DETAIL(*BASIC);
      * >>END-PRE-COMPILER<<
      *--------------------------------------------------------------------------------------------
      /copy 'qxmlgen/copyright.rpgleinc'
      *
      *--------------------------------------------------------------------------------------------
      * Read member script file to generate XML data
      *--------------------------------------------------------------------------------------------
      *
     D ArryDTD         s            100    dim(52)   ctdata perrcd(1)           document template
     D ArryInstruct    s            100    dim(21)   ctdata perrcd(1)           instructions
     D ArryInstPgm     s            100    dim(1192) ctdata perrcd(1)           installer source
     D ba              s              1    inz(  '[')                           open bracket
     D bb              s              1    inz(  ']')                           close bracket
     D Qs              c                   ''''
     D Qd              c                   '"'
     D aa              s              5u 0 inz
     D vrcvar          s            400
     D String          s           2000    varying
     D genSrcFile      s             30    varying
      *
      *----------------------------------------------------------------
      * command definition fields
      *----------------------------------------------------------------
     D vcpgm           s             10                                         cmd processing
     D vCLIB           s             10
     D vSFILE          s             10                                         SOURCE FILE NAM
     D vSLIB           s             10
     D vSMBR           s             10                                         SOURCE MBR
     D vVPGM           s             10                                         VALIDITY CHECKR
     D vVLIB           s             10
      *
     D vMODE           ds
     D  vMODE_PROD             1      1
     D  vMODE_DEBUG            2      2
     D  vMODE_SERVICE          3      3
     D  vMODE_Res              4     10
      *
     D vALW            ds            15
     D  vALW_BPGM              1      1
     D  vALW_IPGM              2      2
     D  vALW_EXEC              3      3
     D  vALW_INTERACT          4      4
     D  vALW_BATCH             5      5
     D  vALW_BREXX             6      6
     D  vALW_IREXX             7      7
     D  vALW_BMOD              8      8
     D  vALW_IMOD              9      9
     D  vALW_Res              10     15
      *
     D vALWLM          s             10    inz('YES ')
     D vPMFIL          s             10                                         PROMPT OVR FILE
     D vPMLIB          s             10
     D vMSFIL          s             10                                         MESSAGE FILE
     D vMSLIB          s             10
     D vHLPNL          s             10                                         HELP PANEL GRP
     D vHLIB           s             10
     D vHLPID          s             10                                         HELP ID
     D vPLIB           s             10                                         PRODUCT LIBRARY
     D vOVPGM          s             10                                         OVERRIDE PROMPT
     D vOVLIB          s             10
     D vTEXT           s             50                                         TEXT
      *
      *----------------------------------------------------------------
      * Error return code parm for APIs.
      *----------------------------------------------------------------
     D errCode         ds                  qualified
     D  bytPrv                       10i 0 inz(%size(errCode))
     D  bytAvl                       10i 0
     D  excID                         7a
     D  reserved_1                    1a
     D  excDta                      256a
      *
      *---------------------------------------------------------------------------------------------
      *  Imported procedures and functions:
      *---------------------------------------------------------------------------------------------
      /copy 'qxmlgen/xmlgenrs_h.rpgleinc'
      *
      * Define function prototype to remove *IMMED from BNDSRVPGM parameter
     D chgBndSrvPgmParm...
     D                 PR                        like(string)                   like(string_t)
     D                                     extproc('chgBndSrvPgmParm')
     D  i_command                          const like(string)                   like(string_t)
      *
      *---------------------------------------------------------------------------------------------
      * Create private Prototypes
      *---------------------------------------------------------------------------------------------
     D rtvCondition...
     D                 PR                  like(string_t)
     D                                     extproc('rtvCondition')
     D  i_string                           value like(string_t)
      *
      *---------------------------------------------------------------------------------------------
      * Create Prototypes for C functions
      *---------------------------------------------------------------------------------------------
      *  Tokenize String
     D strtok          PR              *          extproc('strtok')
     D  i_string                       *   value  options(*string)
     D  i_token                        *   value  options(*string)
      *
      *---------------------------------------------------------------------------------------------
      * Create Prototypes for calls
      *---------------------------------------------------------------------------------------------
     D qcdrcmdi        PR                  ExtPgm('QCDRCMDI')                   COMMAND DEFINITIONS
     D  o_rcvVar                  32767a          options(*varsize)             RECEIVER
     D  i_lenRcvVar                  10i 0 const                                LENGTH OF RECVR
     D  i_format                      8    const                                FORM TYPE
     D  i_qCmd                       20    const                                CMD   LIB
     D  io_errCode                32767a          options(*varsize)             ERROR CODE
      *
      *---------------------------------------------------------------------------------------------
      * system -- Execute a Command
      *---------------------------------------------------------------------------------------------
      *     Return value       Meaning
      *     ----------------   --------------------------------------
      *     0                  the command is successful
      *     -1                 for a NULL pointer
      *     1                  the command fails
     d system          pr            10i 0 extproc('system')
     d  i_clCommand                    *   value options(*string)
      *
     d EXCP_MSGID      s              7a   import('_EXCP_MSGID')
      *
      *---------------------------------------------------------------------------------------------
      * values extracted from mbr script command
     D xinclude        s              4a                                        gen compile code?
     D xmbr            s             10a                                        member name
     D xmbratr         s             10a                                        source mbr attr
     D xfromsrcf       s             10a                                        copy from src file
     D xfromsrcl       s             10a                                        copy from src lib
     D xtosrcf         s             10a                                        copy to src file
     D xobjtype        s             10a   inz varying                          object type
     D xgencrt         s              4a                                        gen compile code?
     D xparam          s            200a                                        optional parameter
     D xcondition      s            200a                                        compile condition
     D xcommand        s                   like(string_t) inz                   cl/sql command
     D xParmVal        s                   like(string_t) inz                   cl/sql command
     D xrelease        s             10a                                        compile condition
     D xdltsplf        s             10a                                        compile condition
     D xmsg            s             52a   inz                                  cond. msg text
     D xvalues         ds
     D  xvalues_entry                11a   inz dim(10)
     D values          s            128a   inz
     D value           s             10a   based(pValue)
     D xcndData        s            632a   inz varying
     D xobj            s             10a   inz varying
     D xlib            s             10a   inz varying
     D xrtnlib         s             11a   inz varying
     D xvar            s             11a   inz varying
     D xvalue          s             64a   inz varying
     D xrtnvrs         s             15a   inz varying
     D xsrcfile        s             10a   inz varying
     D xsrclib         s             10a   inz varying
     D xsrcmbr         s             10a   inz varying
      *
     D cc              s             10i 0 inz
     D xmlString       s           2000a   inz varying
     D text            ds            50    qualified
     D  version               35     50a
     D clCommand       s            500a   inz varying
      *
     D xScriptSource   s            240a   inz varying
     D xMbrSource      s            240a   inz varying
      *
     D cMsg_abnEnd     C                   const('Command ended in error. See -
     D                                     job log for etails')
      *
     D cMEMBER_TEXT    C                   'XML Install Package: %UTILITY%'
      *
     D cEOF            C                   const(*on )
      *
     D cALL_COLORS     S             32a   inz  (x'20212425+
     D                                             222326+
     D                                             28292A2B2C2D2E+
     D                                             30313435+
     D                                             323336+
     D                                             38393C3D+
     D                                             3A3B3E+
     D                                             272F373F')
      *
     D cALL_BLANKS     S                   like(cALL_COLORS) inz
      *
      *  *ENTRY parameters
     D scriptFile      S             10a
     D scriptLib       S             10a
     D scriptMbr       S             10a
     D XML_file        S             10a
     D XML_lib         S             10a
     D XML_mbr         S             10a
     D scrID           S             10a
     D encoding        S             10a
     D author          S             20a
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
      *----------------------------------------------------------------
     C     *entry        plist
     C                   parm                    scriptFile                     script file
     C                   parm                    scriptLib                      - library
     C                   parm                    scriptMbr                      - member
     C                   parm                    XML_file                       XML file
     C                   parm                    XML_lib                        - library
     C                   parm                    XML_mbr                        - member
     C                   parm                    scrID                          application name
     C                   parm                    encoding                       XML Encoding
     C                   parm                    author                         appl author
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
      * Open script file.
      *---------------------------------------------------------------------
     C                   if        not openScript(scriptFile :
     C                                            scriptLib  :
     C                                            scriptMbr  )
     C                   callp     sndMessage('CPF9898'   :
     C                                        cMsg_abnEnd :
     C                                        '*ESCAPE'   )
     C                   endif
      *
      *---------------------------------------------------------------------
      * Open XML file.
      *---------------------------------------------------------------------
     C                   if        not openXML(XML_file   :
     C                                         XML_lib    :
     C                                         XML_mbr    :
     C                                         '*WRITE'   )
     C                   callp     sndMessage('CPF9898'   :
     C                                        cMsg_abnEnd :
     C                                        '*ESCAPE'   )
     C                   endif
      *
      *----------------------------------------------------------------
      * generate xml header statement.
      *----------------------------------------------------------------
     C                   callp     writeXML('<?xml version=' + qd + '1.0'+
     C                                       qd + ' encoding=' + qd +
     C                                       %trim(Encoding)+qd+'?>'     )
      *
      *----------------------------------------------------------------
      * Read down in script to get whether or not to generate the DTD .
      *      XMLGENINC  XINCLUDE(*YES) *YES, *NO
      *
      * If user has selected to not include install program,
      * then do not include DTD, install instructions, or install_pgm.
      *----------------------------------------------------------------
     C                   dow       readScript(xScriptSource) <> cEOF
      *
     C                   eval      xScriptSource = rmvClRem(xScriptSource)      remove comment
     C                   If        xScriptSource = ''
     C                   Iter
     C                   Endif
      *
     C                   If        %scan('XMLGENINC': uCase(xScriptSource)) > 0
     C                   eval      xinclude = getKwdData('XINCLUDE'    :
     C                                                   xScriptSource )
     C                   leave
     C                   endif
      *
     C                   enddo
      *
     C                   exsr      srLoadDTD                                    Load DTD
      *
     C                   callp     writeXML('<upload'+
     C                                      '  appname='    + qd +
     C                                                      %trimr(ScrID)
     C                                                      + qd +
     C                                      '  appauthor='  + qd +
     C                                                      %trim(author)
     C                                                      + qd +
     C                                      '  appblddate=' + qd +
     C                                                      %editc(*date:'Y')
     C                                                      + qd + '>'         )
      *
     C                   if        xinclude='*YES'
     C                   exsr      srLoadInstr                                  Load instructions
     C                   exsr      srLoadInstPgm                                Load install pgm
     C                   endif
      *
      *---------------------------------------------------------------------
      * Spin through script file and load data from tags as the occur.
      *      XMLGENMBR  XMBR(XMLGEN) XMBRATR(CLP) XFROMSRCF(JCLSRC) +
      *                   XFROMSRCL(JCRCMDS) XTOSRCF(QCLSRC) +
      *                   XOBJTYPE(*PGM) +
      *                   XPARAM(OPTION(*SRCDBG) USRPRF(*OWNER)) +
      *                   XGENCRT(*YES) +
      *                   XCND(aCondition)
      *
      *      XMLGENCMD  XCMD(CRTDTAARA DTAARA(&TOLIB/TEST) +
      *                   TYPE(*CHAR) LEN(10) VALUE(A)) +
      *                   XCND(aCondition) +
      *                   XRLS(*EQ V5R1M0) +
      *                   XDLTSPLF(*NONE)
      *
      *      XMLGENSQL  XCMD(SELECT * FROM MYLIB/MYFILE) +
      *                   XCND(aCondition)
      *
      *      XMLGENCND  XMSG('Message presented to the user') +
      *                   XVALUES(Y N) XVAR(*NONE)
      *
      *      XMLGENOBJD XOBJ(BASICS1) XLIB(*LIBL) XTYPE(*SRVPGM) +
      *                   XRTNLIB(&BASICS1LIB) +
      *                   XCND(aCondition)
      *
      *      XMLGENSET  XVAR(&VARNAME) +
      *                   XVALUE(aValue) +
      *                   XCND(aCondition)
      *---------------------------------------------------------------------
     C                   callp     setllScript(1)
      *
     C                   dow       readScript(xScriptSource) <> cEOF
      *
     C                   eval      xScriptSource = rmvClRem(xScriptSource)      remove comment
     C                   If        xScriptSource = ''
     C                   Iter
     C                   Endif
      *
      * Check for XMLGEN command ...
     C                   select
      * ... XMLGENMBR
     C                   when      %scan('XMLGENMBR':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   if        string <> ''
     C                   exsr      srParseMbrVal                                extract mbr script
     C                   exsr      srLoadMbr                                    load into xml
     C                   endif
      * ... XMLGENCMD
     C                   when      %scan('XMLGENCMD':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   if        string <> ''
     C                   exsr      srAddTgtRls                                  add parm TGTRLS
     C                   exsr      srParseCmdVal                                extract cmd script
     C                   exsr      srLoadExc
     C                   endif
      * ... XMLGENSQL
     C                   when      %scan('XMLGENSQL':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   exsr      srParseSqlVal                                extract sql script
     C                   exsr      srLoadSql
      * ... XMLGENCND
     C                   when      %scan('XMLGENCND':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   exsr      srParseCndVal                                extract cnd values
     C                   exsr      srLoadCnd
      * ... XMLGENOBJD
     C                   when      %scan('XMLGENOBJD':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   exsr      srParseObjDVal                               extract values
     C                   exsr      srLoadObjD
      * ... XMLGENSET
     C                   when      %scan('XMLGENSET':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   exsr      srParseSetVal                                extract values
     C                   exsr      srLoadSet
      * ... XMLGENVRS
     C                   when      %scan('XMLGENVRS':ucase(xScriptSource)) > 0
     C                   eval      string = loadScriptString(xScriptSource)     load into one string
     C                   eval      string = rmvClRem(string)                    remove comment
     C                   eval      string = fmtClCmd(string)                    format command
     C                   exsr      srParseVrsVal                                extract values
     C                   exsr      srSetVersion
      * ... others
     C                   other
     C                   eval      string = ''
     C                   endsl
      *
     C                   enddo
      *
      *----------------------------------------------------------------
      * generate completed message code.
      *----------------------------------------------------------------
     C                   callp     writeXML('<sendmsg  sendmsgid=' + qd +
     C                                      'CPF9897' + qd + ' ' +
     C                                      'sendmsgtype = ' + qd +
     C                                      '*COMP     ' + qd + '>' +
     C                                      '<!' + ba + 'CDATA' + ba    )
      *
     C                   callp     writeXML('Application ' + %trimr(ScrID) +
     C                                      ' successfully installed.  '   )
      *
     C                   callp     writeXML(bb + bb + '>  </sendmsg>')
      *
     C                   callp     writeXML('</upload>')
      *
     C                   callp     closeScript
     C                   callp     closeXML
      *
     C                   eval      *inlr=*on
     C                   return
      *
      *----------------------------------------------------------------
      * Generate DTD validation specs, Install instructions and
      * Install program.
      *----------------------------------------------------------------
     C     srLoadDTD     begsr
      *
     C                   for       aa = 1 to %elem(ArryDTD)
     C                   callp     writeXML(ArryDTD(aa))
     C                   endfor
      *
     C                   endsr
      *
      *----------------------------------------------------------------
      * load <upload attributes
      * Note:  Change 'Craig Rutledge' to your name here.
      *----------------------------------------------------------------
     C     srLoadInstr   begsr
      *
      *----------------------------------------------------------------
      * load <install_instructions>
      *  the bracket symbol is not available on all keyboards.
      *  (namely mine!) so I will use the hex values. BA=open  BB=close
      * Load instruction array to outfile.
      *----------------------------------------------------------------
      *
     C                   callp     writeXML('<install_instructions>' +
     C                                      '<!' + ba + 'CDATA' + ba )
      *
     C                   for       aa = 1 to %elem(ArryInstruct)
     C                   callp     writeXML(ArryInstruct(aa))
     C                   endfor
      * close brackets
     C                   callp     writeXML(bb + bb + '> ' +
     C                                      ' </install_instructions>')
      *
     C                   endsr
      *
      *----------------------------------------------------------------
      * load <install_program>    Load RPG source array to outfile.
      *----------------------------------------------------------------
     C     srLoadInstPgm begsr
      *
     C                   callp     writeXML('<install_program>' +
     C                                      '<!' + ba + 'CDATA' + ba)
      *
     C                   for       aa = 1 to %elem(ArryInstPgm)
     C                   callp     writeXML(ArryInstPgm(aa))
     C                   endfor
      * close brackets
     C                   callp     writeXML(bb + bb + '> ' +
     C                                      ' </install_program>')
     C                   endsr
      *
      *----------------------------------------------------------------
      * Load member into xml output
      *----------------------------------------------------------------
     C     srLoadMbr     begsr
      *
      *---------------------------------------------------------------------
      * Open member file.
      *---------------------------------------------------------------------
     C                   if        not openMbr(xfromsrcf :
     C                                         xfromsrcl :
     C                                         xmbr      )
     C                   callp     sndMessage('CPF9898'   :
     C                                        cMsg_abnEnd :
     C                                        '*ESCAPE'   )
     C                   endif
      *
      *  send status message to user
     C                   callp     writeXML('<sendmsg  sendmsgid=' + qd +
     C                                      'CPF9897' + qd + ' ' +
     C                                      'sendmsgtype = ' + qd +
     C                                      '*STATUS   ' + qd + '>' +
     C                                      '<!' + ba + 'CDATA' + ba    )
      *
     C                   callp     writeXML('Installing ' + %trimr(xmbr) +
     C                                      '  type ' + %trimr(xmbratr) +
     C                                      ' - in progress.'            )
      *
     C                   callp     writeXML(bb + bb + '>  </sendmsg>')
      *
      *  member attributes
     C                   callp     writeXML('<!-- START OF MEMBER  -->')
      *
     C                   callp     writeXML('<mbr')
      * MBRNAME
     C                   callp     writeXML('mbrname =  ' + qd + xmbr + qd)
      * MBRTYPE
     C                   callp     writeXML('mbrtype =  ' + qd + xmbratr + qd)
      * MBRTEXT
     C                   callp     writeXML('mbrtext =  ' + qd +
     C                                      GetMbrTxt(xfromsrcf:xfromsrcl:xmbr)
     C                                      + qd                               )
      * SRCFILE
     C                   callp     writeXML('srcfile =  ' + qd + xtosrcf + qd)
      * SRCLIB
     C                   callp     writeXML('srclib  =  ' + qd + 'selected  '
     C                                      + qd                               )
      * SRCLEN
     C                   callp     writeXML('srclen  =  ' + qd +
     C                                       %editc(%dec(getMbrRcdLen:5:0): 'X')
     C                                      + qd                               )
      * CSSID
     C                   callp     writeXML('srccssid=  ' + qd +
     C                                       %editc(%dec(getMbrCCSID :5:0): 'X')
     C                                      + qd + '>'                         )
      *
      *  ----------------------------------------------------------------------------------------
      *   load the member data into text file.
      *  -----------------------------------------------------------------------------------------
     C                   callp     writeXML('<copysrc>' +
     C                                      '<!' + ba + 'CDATA' + ba)
      *
      *    ----------------------------------------------------------------
      *    read through the member loading source record to outfile
      *    ----------------------------------------------------------------
     C                   dow       readMbr(xMbrSource) <> cEOF
     C                   eval      xMbrSource = %xlate(cALL_COLORS
     C                                                 : cALL_BLANKS
     C                                                 : xMbrSource)
     C                   callp     writeXML(xMbrSource)
     C                   enddo
      *
     C                   callp     closeMbr
      *
      * close brackets
     C                   callp     writeXML(bb + bb + '>  </copysrc>')
     C                   callp     writeXML('</mbr>')
      *
      *    ----------------------------------------------------------------
      *    generate standard object creation code
      *    if flag is set to '*YES'
      *    ----------------------------------------------------------------
     C                   if        xgencrt='*YES'
     C                   if        xmbratr= 'CMD  '
     C                   exsr      srCrtCmd                                     Create Command defin
     C                   else
      ***                callp     writeXML('<sendmsg  sendmsgid=' + qd +
      ***                                   'CPF9897' + qd + ' ' +
      ***                                   'sendmsgtype = ' + qd +
      ***                                   '*COMP     ' + qd + '>' +
      ***                                   '<!' + ba + 'CDATA' + ba    )
     C                   callp     writeXML('<compile  condition=' + qd +
     C                                      %trim(xcondition) + qd + '>' +
     C                                      '<!' + ba + 'CDATA' + ba)
      *
     C                   eval      genSrcFile = ' SRCFILE(&tolib/' +
     C                                          %trimr(xtosrcf) + ')'
     C                   select
     C                   when      xmbratr = 'RPGLE    '  and
     C                             xobjtype = '*PGM     '
     C                   eval      string = 'CRTBNDRPG PGM(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile
      *
     C                   when      xmbratr = 'SQLRPGLE '  and
     C                             xobjtype = '*PGM     '
     C                   eval      string = 'CRTSQLRPGI OBJ(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile  +
     C                             ' COMMIT(*NONE)'
      *
     C                   when      xmbratr = 'RPG      '  and
     C                             xobjtype = '*PGM     '
     C                   eval      string = 'CRTRPGPGM PGM(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile
      *
     C                   when      xmbratr = 'CLP      '  and
     C                             xobjtype = '*PGM     '
     C                   eval      string = 'CRTCLPGM PGM(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile
      *
     C                   when      xmbratr = 'CLLE     '  and
     C                             xobjtype = '*PGM     '
     C                   eval      string = 'CRTBNDCL PGM(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile
      *
     C                   when      xmbratr = 'PNLGRP    '
     C                   eval      string = 'CRTPNLGRP PNLGRP(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile
      *
     C                   when      xmbratr = 'DSPF      '
     C                   eval      string = 'CRTDSPF FILE(&tolib/'+
     C                             %trimr(xmbr) +')' + genSrcFile
      *
     C                   when      xmbratr = 'PRTF      '
     C                   eval      string = 'CRTPRTF FILE(&tolib/'+
     C                             %trimr(xmbr) +')' + gensrcfile
      *
     C                   when      xmbratr = 'PF        '
     C                   eval      string = 'CRTPF FILE(&tolib/'+
     C                             %trimr(xmbr) +')' + gensrcfile
      *
     C                   when      xmbratr = 'LF        '
     C                   eval      string = 'CRTLF FILE(&tolib/'+
     C                             %trimr(xmbr) +')' + gensrcfile
     C                   endsl
      *
      * add XPARAM
     C                   eval      string = string + ' ' + %trim(xparam)
      *
      * multiline command
     C                   callp     writeXMLString(string)
      *
      * close brackets
     C                   callp     writeXML(bb + bb + '> ' +
     C                                      ' </compile>'  )
     C                   endif
     C                   endif
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * The command data was loaded into a single string.  This section
      * will break the commands into 100 byte chuncks and write to xml.
      *---------------------------------------------------------------------------------------------
     C     srLoadExc     begsr
      *
     C                   callp     writeXML('<qcmdexc' +
     C                                        ' condition=' + qd +
     C                                          %trim(xcondition) + qd +
     C                                        ' release=' + qd +
     C                                          %trim(xrelease) + qd +
     C                                        ' dltsplf=' + qd +
     C                                          %trim(xdltsplf) + qd +
     C                                        '>' +
     C                                        '<!' + ba + 'CDATA' + ba)
      *
     C                   callp     writeXMLString(xcommand)
      *
      * close brackets
     C                   callp     writeXML(bb + bb + '>  </qcmdexc>')
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * The sql-command data was loaded into a single string.  This section
      * will break the commands into 100 byte chuncks and write to xml.
      *---------------------------------------------------------------------------------------------
     C     srLoadSql     begsr
      *
     C                   callp     writeXML('<execsql  condition=' + qd +
     C                                      %trim(xcondition) + qd + '>' +
     C                                      '<!' + ba + 'CDATA' + ba)
      *
     C                   callp     writeXMLString(xcommand)
      *
      * close brackets
     C                   callp     writeXML(bb + bb + '>  </execsql>')
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * The condition data was loaded into a single string.  This section
      * will break the data into 100 byte chuncks and write to xml.
      *---------------------------------------------------------------------------------------------
     C     srLoadCnd     begsr
      *
     C                   callp     writeXMLString('<qrycond')
     C                   callp     writeXMLString('  msg=' + qd +
     C                                                 %trim(xmsg) + qd)
     C                   callp     writeXMLString('  values=' + qd +
     C                                                 %trim(xvalues) + qd)
     C                   callp     writeXMLString('  var=' + qd +
     C                                                 %trim(xvar) + qd + '>')
     C                   callp     writeXMLString('<!' + ba + 'CDATA' + ba )
      *
     C                   callp     writeXML(bb + bb + '>  </qrycond>')
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * The retrieve object description data was loaded into a single string.  This section
      * will break the data into 100 byte chuncks and write to xml.
      *---------------------------------------------------------------------------------------------
     C     srLoadObjD    begsr
      *
     C                   eval      xmlString = '<rtvobjd ' +
     C                                   ' condition=' +
     C                                        Qd + %trim(xcondition) + Qd +
     C                                   ' obj='     + Qd + xobj     + Qd +
     C                                   ' lib='     + Qd + xlib     + Qd +
     C                                   ' objtype=' + Qd + xobjtype + Qd
      *
     C                   if        (xrtnlib <> '')
     C                   eval      xmlString = xmlString +
     C                                   ' rtnlib=' + Qd + xrtnlib + Qd
     C                   endif
      *
     C                   eval      xmlString = xmlString + '>'
      *
     C                   callp     writeXMLString(xmlString)
      *
     C                   callp     writeXMLString('<!' + ba + 'CDATA' + ba)
      *
     C                   callp     writeXML(bb + bb + '>  </rtvobjd>')
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * The 'set' data was loaded into a single string.  This section
      * will break the data into 100 byte chuncks and write to xml.
      *---------------------------------------------------------------------------------------------
     C     srLoadSet     begsr
      *
     C                   eval      xmlString = '<chgvar  ' +
     C                                   ' condition=' +
     C                                        Qd + %trim(xcondition) + Qd +
     C                                   ' var='     + Qd + xvar     + Qd +
     C                                   ' value='   + Qd + xvalue   + Qd
      *
     C                   eval      xmlString = xmlString + '>'
      *
     C                   callp     writeXMLString(xmlString)
      *
     C                   callp     writeXMLString('<!' + ba + 'CDATA' + ba)
      *
     C                   callp     writeXML(bb + bb + '>  </chgvar>')
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * Retrieves and sets the version number of the utility.
      *---------------------------------------------------------------------------------------------
     C     srSetVersion  begsr
      *
     C                   eval      text = replace(
     C                                     '%UTILITY%': cMEMBER_TEXT: scriptMbr)
     C
     C                   eval      text.version = getVersionInfo(
     C                                               xsrcfile: xsrclib: xsrcmbr)
      *
     C                   eval      clCommand = 'CHGPFM +
     C                                            FILE(' +
     C                                              %trim(XML_lib) + '/' +
     C                                              %trim(XML_file) + ') +
     C                                            MBR(' +
     C                                              %trim(XML_mbr) + ') +
     C                                            TEXT(''' + %trim(text) + ''')'
      *
     C                   callp     system(clCommand)
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from mbr script command
      * xcondition     s             10                                         compile condition
      * xmbr           s             10                                         member name
      * xmbratr        s             10                                         source mbr attr
      * xfromsrcf      s             10                                         copy from src file
      * xfromsrcl      s             10                                         copy from src lib
      * xtosrcf        s             10                                         copy to src file
      * xobjtype       s              7                                         object type
      * xgencrt        s              4                                         gen compile code?
      * xparam         s            200                                         optional parameter
      *---------------------------------------------------------------------------------------------
     C     srParseMbrVal begsr
      *
     C                   eval      xcondition = rtvCondition(string)
      *
     C                   eval      xmbr       = getKwdData('XMBR'   : string)
      *
     C                   eval      xmbratr    = getKwdData('XMBRATR': string)
      *
     C                   eval      xfromsrcf  = getKwdData('XFROMSRCF': string)
      *
     C                   eval      xfromsrcl  = getKwdData('XFROMSRCL': string)
      *
     C                   eval      xtosrcf    = getKwdData('XTOSRCF'  : string)
      *
     C                   eval      xobjtype   = getKwdData('XOBJTYPE' : string)
      *
     C                   eval      xgencrt    = getKwdData('XGENCRT'  : string)
      *
     C                   eval      xparam     = getKwdData('XPARAM'   : string)
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
      * extract values from cmd script command
      * xcondition     s             10                                         compile condition
      * xcommand       s           2000                                         cl command
      * xrelease       s             10                                         i5 version
      *---------------------------------------------------------------------------------------------
     C     srParseCmdVal begsr
      *
     C                   eval      xcondition = rtvCondition(string)
      *
     C                   eval      xcommand = getKwdData('XCMD'     : string)
     C                   eval      xcommand = rmvQuotes(xcommand)
     C                   eval      xcommand = replace('&TOLIB'  :
     C                                                xcommand  :
     C                                                '&tolib'  )
      *    Remove *IMMED from BNDSRVPGM parameter
     C                   eval      xcommand = chgBndSrvPgmParm(xcommand)
      *
     C                   eval      xrelease = getKwdData('XRLS'     : string)
      *
     C                   if        xrelease = ''
     C                   eval      xrelease = '*CURRENT'
     C                   endif
      *
     C                   eval      xdltsplf = getKwdData('XDLTSPLF' : string)
      *
     C                   if        xdltsplf = ''
     C                   eval      xdltsplf = '*NONE'
     C                   endif
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * add parameter TGTRLS(*CURRENT) to command
      * xcommand       s           2000                                         cl command
      *---------------------------------------------------------------------------------------------
     C     srAddTgtRls   begsr
      *
     C                   if        not startsWith('CRTRPGMOD': xcommand) and    | RPG
     C                             not startsWith('CRTRPGPGM': xcommand) and    |
     C                             not startsWith('CRTBNDRPG': xcommand) and    |
     C                             not startsWith('CRTCLMOD' : xcommand) and    | CL
     C                             not startsWith('CRTCLPGM' : xcommand) and    |
     C                             not startsWith('CRTBNDCL' : xcommand) and    |
     C                             not startsWith('CRTCMOD'  : xcommand) and    | C
     C                             not startsWith('CRTBNDC'  : xcommand) and    |
     C                             not startsWith('CRTPGM'   : xcommand)        | Pgm
     C                   leavesr
     C                   endif
      *
     C                   if        %scan('TGTRLS(': xcommand) = 0
     C                   leavesr
     C                   endif
      *
     C                   eval      xcommand = xcommand + ' TGTRLS(*CURRENT)'
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from sql script command
      * xcondition     s             10                                         compile condition
      * xcommand       s           2000                                         sql statement
      *---------------------------------------------------------------------------------------------
     C     srParseSqlVal begsr
      *
     C                   eval      xcondition = rtvCondition(string)
      *
     C                   eval      xcommand  = getKwdData('XSQL'     : string)
      *
     C                   eval      xcommand = rmvQuotes(xcommand)
      *
     C                   eval      xcommand = rmvDblQuotes(xcommand)
      *
     C                   eval      xcommand = replace('&TOLIB'  :
     C                                                xcommand  :
     C                                                '&tolib'  )
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from condition script command
      * xmsg           s             52                                         cond. msg text
      * xvalues        s                                                        cond. values
      *---------------------------------------------------------------------------------------------
     C     srParseCndVal begsr
      *
     C                   eval      xmsg   = getKwdData('XMSG'    : string)
      *
     C                   eval      values = getKwdData('XVALUES'  : string) +
     C                                      x'00'
      *
     C                   eval      pValue = strtok(values: ' ')
      *
     C                   eval      cc = 0
     C                   dow       pValue <> *null
     C                   eval      cc = cc + 1
     C                   eval      xvalues_entry(cc) = %str(pValue)
     C                   eval      pValue = strtok(*null: ' ')
     C                   enddo
      *
     C                   eval      xcndData = ' msg=' + Qd +
     C                                        %trim(xmsg) + Qd +
     C                                        ' values=' + Qd +
     C                                        %trim(xvalues) + Qd
      *
     C                   eval      xvar = getFldName('XVAR': string)
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from retrieve object description script command
      * xobj           s             10                                         object name
      * xlib           s             10                                         library name
      * xobjtype       s             10                                         object type
      * xcondition     s            200                                         compile condition
      *---------------------------------------------------------------------------------------------
     C     srParseObjDValbegsr
      *
     C                   eval      xobj       = getKwdData('XOBJ'     : string)
     C                   eval      xlib       = getKwdData('XLIB'     : string)
     C                   eval      xobjtype   = getKwdData('XOBJTYPE' : string)
     C                   eval      xcondition = rtvCondition(string)
     C                   eval      xrtnlib    = getFldName('XRTNLIB'  : string)
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from 'set' script command
      * xvar           s             10                                         variable name
      * xvalue         s             64                                         variable value
      * xcondition     s            200                                         compile condition
      *---------------------------------------------------------------------------------------------
     C     srParseSetVal begsr
      *
     C                   eval      xvar       = getFldName('XVAR'     : string)
     C                   eval      xvalue     = getKwdData('XVALUE'   : string)
     C                   eval      xcondition = rtvCondition(string)
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * extract values from 'vrs' script command
      * xvar           s             10                                         variable name
      * xvalue         s             64                                         variable value
      * xcondition     s            200                                         compile condition
      *---------------------------------------------------------------------------------------------
     C     srParseVrsVal begsr
      *
     C                   eval      xsrcfile = getKwdData('XSRCFILE' : string)
     C                   eval      xsrclib  = getKwdData('XSRCLIB'  : string)
     C                   eval      xsrcmbr  = getKwdData('XSRCMBR'  : string)
     C                   eval      xrtnvrs  = getFldName('XRTNVRS'  : string)
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * Extract command definitions
      *---------------------------------------------------------------------------------------------
     C     srCrtCmd      begsr
      *
     C                   clear                   errCode
      *
     C                   callp     QCDRCMDI(vrcvar           :
     C                                      %size(vrcvar)    :
     C                                      'CMDI0100'       :
     C                                      xmbr + xfromsrcl :
     C                                      errCode          )
      *
     C                   eval      vCPGM = %subst(vRCVAR:29:10)
     C                   eval      vCLIB = %subst(vRCVAR:39:10)
     C                   eval      vSFILE= %subst(vRCVAR:49:10)
     C                   eval      vSLIB = %subst(vRCVAR:59:10)
     C                   eval      vSMBR = %subst(vRCVAR:69:10)
     C                   eval      vVPGM = %subst(vRCVAR:79:10)
     C                   eval      vVLIB = %subst(vRCVAR:89:10)
     C                   eval      vMODE = %subst(vRCVAR:99:10)
     C                   eval      vALW  = %subst(vRCVAR:109:10)
      *
     C                   if        %subst(vrcvar:124:1) = '0'
     C                   eval      valwlm = '*NO '
     C                   endif
      *
     C                   eval      vPMFIL = %subst(vRCVAR:129:10)
     C                   eval      vPMLIB = %subst(vRCVAR:139:10)
     C                   eval      vMSFIL = %subst(vRCVAR:149:10)
     C                   eval      vMSLIB = %subst(vRCVAR:159:10)
     C                   eval      vHLPNL = %subst(vRCVAR:169:10)
     C                   eval      vHLIB  = %subst(vRCVAR:179:10)
     C                   eval      vHLPID = %subst(vRCVAR:189:10)
     C                   eval      vPLIB  = %subst(vRCVAR:229:10)
     C                   eval      vOVPGM = %subst(vRCVAR:239:10)
     C                   eval      vOVLIB = %subst(vRCVAR:249:10)
     C                   eval      vTEXT  = %subst(vRCVAR:265:50)
      *
      *     ----------------------------------------------------------------
      *     generate Command creation code
      *    ----------------------------------------------------------------
     C                   eval      string = 'XMLGENCMD XCMD(''CRTCMD ' +
     C                                      'CMD(&tolib/' + %trimr(xmbr)  + ')'
      *
      * - -
      *  CMD program
     C                   if        vCLIB = '*LIBL'
     C                   eval      string = string +
     C                             ' PGM(' + %trimr(vCLIB) + '/' +
     C                                       %trimr(vCPGM)  + ')'
     C                   else
     C                   eval      string = string +
     C                             ' PGM(&tolib/' + %trimr(vCPGM)  + ')'
     C                   endif
      *
      * - -
      *  source file
     C                   eval      string = string +
     C                             ' SRCFILE(&tolib/' + %trim(xtosrcf) +
     C                                     ') SRCMBR(' +
     C                                     %trimr(xmbr)  + ')'  +
     C                             ' ALWLMTUSR(' +  %trimr(vALWLM)  + ')' +
     C                             ' HLPID(' +  %trimr(vHLPID)  + ')'
      * - -
      *  Validity checking program
     C                   if        vVPGM > *blanks and
     C                             vVPGM <> '*NONE  '
     C                   if        vVLIB = '*LIBL'
     C                   eval      string = string +
     C                             ' VLDCKR(' + %trimr(vVLIB) + '/' +
     C                                          %trimr(vVPGM)  + ')'
     C                   else
     C                   eval      string = string +
     C                             ' VLDCKR(&tolib/' + %trimr(vVPGM)  + ')'
     C                   endif
     C                   endif
      * - -
      *  Mode in which valid
     C                   eval      string = string + ' MODE('
     C                   if        vMODE_PROD    = '1'
     C                   eval      string = string + ' *PROD'
     C                   endif
     C                   if        vMODE_DEBUG   = '1'
     C                   eval      string = string + ' *DEBUG'
     C                   endif
     C                   if        vMODE_SERVICE = '1'
     C                   eval      string = string + ' *SERVICE'
     C                   endif
     C                   eval      string = string + ')'
      * - -
      *  Where allowed to run
     C                   eval      string = string + ' ALLOW('
     C                   if        vALW_BPGM     = '1'
     C                   eval      string = string + ' *BPGM'
     C                   endif
     C                   if        vALW_IPGM     = '1'
     C                   eval      string = string + ' *IPGM'
     C                   endif
     C                   if        vALW_EXEC     = '1'
     C                   eval      string = string + ' *EXEC'
     C                   endif
     C                   if        vALW_INTERACT = '1'
     C                   eval      string = string + ' *INTERACT'
     C                   endif
     C                   if        vALW_BATCH    = '1'
     C                   eval      string = string + ' *BATCH'
     C                   endif
     C                   if        vALW_BREXX    = '1'
     C                   eval      string = string + ' *BREXX'
     C                   endif
     C                   if        vALW_IREXX    = '1'
     C                   eval      string = string + ' *IREXX'
     C                   endif
     C                   if        vALW_BMOD     = '1'
     C                   eval      string = string + ' *BMOD'
     C                   endif
     C                   if        vALW_IMOD     = '1'
     C                   eval      string = string + ' *IMOD'
     C                   endif
     C                   eval      string = string + ')'
      * - -
      *  Message file for prompt text
     C                   if        vPMFIL > *blanks and
     C                             vPMFIL <> '*NONE  '
     C                   if        vPMLIB = '*LIBL'
     C                   eval      string = string +
     C                             ' PMTFILE(' + %trimr(vPMLIB) + '/' +
     C                                          %trimr(vPMFIL)  + ')'
     C                   else
     C                   eval      string = string +
     C                             ' PMTFILE(&tolib/' + %trimr(vPMFIL)  + ')'
     C                   endif
     C                   endif
      * - -
      *  Help panel group
     C                   if        vHLPNL > *blanks and
     C                             vHLPNL <> '*NONE  '
     C                   if        vHLIB = '*LIBL'
     C                   eval      string = string +
     C                             ' HLPPNLGRP(' + %trimr(vHLIB) + '/' +
     C                                          %trimr(vHLPNL)  + ')'
     C                   else
     C                   eval      string = string +
     C                             ' HLPPNLGRP(&tolib/' + %trimr(vHLPNL)  + ')'
     C                   endif
     C                   endif
      *
      * - -
      *  Product library
     C                   if        (vPLIB = '*NOCHG')  or
     C                             (vPLIB = '*NONE' )
     C                   eval      string = string +
     C                             ' PRDLIB(' + %trimr(vPLIB) + ')'
     C                   else
     C                   eval      string = string +
     C                             ' PRDLIB(&tolib)'
     C                   endif
      * - -
      *  Prompt override program
     C                   if        vOVPGM > *blanks and
     C                             vOVPGM <> '*NONE  '
     C                   if        vOVLIB = '*LIBL'
     C                   eval      string = string +
     C                             ' PMTOVRPGM(' + %trimr(vOVLIB) + '/' +
     C                                          %trimr(vOVPGM)  + ')'
     C                   else
     C                   eval      string = string +
     C                             ' PMTOVRPGM(&tolib/' + %trimr(vOVPGM)  + ')'
     C                   endif
     C                   endif
      * - -
      *  Text
     C                   eval      string = string + ' TEXT(*SRCMBRTXT)'
      * - -
      *  Additional parameters
     C                   eval      string = string + ' ' + %trim(xparam) + ') '+
     C                                      'XCND(' + %trim(xcondition) + ')'
     C                   exsr      srParseCmdVal                                extract cmd script
     C                   exsr      srLoadExc
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      *  Get condition from command string
      *---------------------------------------------------------------------------------------------
     P rtvCondition...
     P                 B
     D                 PI                  like(string_t)
     D  i_string                           value like(string_t)
      *
      *  return value
     D condition       S                   like(string_t)
      *
      *  local fields
     D tmpStr          S                   inz   like(condition)
     D pValue          S               *   inz
      *-------------------------------------------------------------------*
      *
     C                   eval      tmpStr = getKwdData('XCND'    : i_string)
      *
     C                   if        tmpStr = ''
     C                   eval      condition = '*NONE'
     C                   else
     C                   eval      pValue = strtok(tmpStr: ' ')
     C                   dow       pValue <> *null
     C                   if        condition = ''
     C                   eval      condition = rmvQuotes(%trim(%str(pValue)))
     C                   else
     C                   eval      condition = %trimr(condition) + ' ' +
     C                                         rmvQuotes(%trim(%str(pValue)))
     C                   endif
     C                   eval      pValue = strtok(*null: ' ')
     C                   enddo
     C                   endif
      *
     C                   Return    condition
      *
     P                 E
      *
      *---------------------------------------------------------------------------------------------
      *  Remove *IMMED from BNDSRVPGM parameter
      *---------------------------------------------------------------------------------------------
     P chgBndSrvPgmParm...
     P                 B
     D                 PI                        like(string)
     D  i_command                          const like(string)
      *
      *  return value
     D command         S                   like(string_t) inz
      *
      *  local fields
     D x               S             10I 0 inz
     D y               S             10I 0 inz
     D k               S             10I 0 inz
     D i               S             10I 0 inz
     D BNDSRVPGM       C                   'BNDSRVPGM'
     D IMMED           C                   '*IMMED'
      *-------------------------------------------------------------------*
      *
     C                   eval      x = %scan(BNDSRVPGM + '(': i_command)
     C                   if        x = 0
     C                   return    i_command
     C                   endif
      *
     C                   eval      x = %scan('(': i_command: x)
     C                   eval      y = x
     C                   dou       k = 0 and y < %len(i_command)
     C                   select
     C                   when      %subst(i_command: y: 1) = '('
     C                   eval      k = k + 1
     C                   when      %subst(i_command: y: 1) = ')'
     C                   eval      k = k - 1
     C                   endsl
     C                   if        k <> 0
     C                   eval      y = y + 1
     C                   endif
     C                   enddo
      *
     C                   if        k <> 0
     C                   return    i_command
     C                   endif
      *
     C                   eval      command = i_command
      *
     C                   eval      i = 1
     C                   dow       i > 0
     C                   if        i > %len(command)
     C                   eval      i = 0
     C                   else
     C                   eval      i = %scan(IMMED: command: x)
     C                   if        i > 0 and i > x and i < y
     C                   eval      command =
     C                                %replace('': command: i: %len(IMMED))
     C                   endif
     C                   endif
     C                   enddo
      *
     C                   Return    command
      *
     P                 E
      *
** CTDATA(ArryDTD)        Document template
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
** CTDATA(ArryInstruct)   install_instructions
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
** CTDATA(ArryInstPgm)    install_program
      * /// START OF INSTALL PGM HERE   ************************** ///
      *---------------------------------------------------------------------------------------
      * CRTBNDRPG PGM(QTEMP/XMLINST) SRCFILE(ISPHERE/QBUILD) SRCMBR(*PGM)
      *---------------------------------------------------------------------------------------
      * Parse / Install from xml text into source members and objects.
      * Copyright (C) 2001    Craig Rutledge    <craig_rutledge@mohawkind.com>
      * Martin Rowe    <Martin@dbg400.net>          scripting cmd prompts
      * David George   <webmaster@400times.co.uk>   intellectual input
      * Thomas Raddatz <thomas.raddatz@tools400.de> execute SQL statements
      * Thomas Raddatz <thomas.raddatz@tools400.de> conditions
      * Thomas Raddatz <thomas.raddatz@tools400.de> release
      * Thomas Raddatz <thomas.raddatz@tools400.de> retrieve object description
      *
      * Use xml tags in text to trigger:
      * 1. Parse text into source members (create srcfile & member if required).
      * 2. Compile source into objects.
      * 3. Send installation progress user messages.
      * 4. Execute qcmdexc as required.
      * 5. Execute SQL statements as required.
      *
      * This program is free software, you can redistribute it and/or modify it
      * under the terms of the GNU General Public License as published by
      * the Free Software Foundation.  See GNU General Public License for details
      *---------------------------------------------------------------------------------------
      * >>PRE-COMPILER<<
      *   >>CRTCMD<< CRTBNDRPG    PGM(&LI/&OB) SRCFILE(&SL/&SF) SRCMBR(*PGM) +
      *                           DBGVIEW(*LIST) OPTION(*EVENTF);
      *   >>EXECUTE<<
      * >>END-PRE-COMPILER<<
      *---------------------------------------------------------------------------------------
     H DFTACTGRP(*NO) ACTGRP(*CALLER) BNDDIR('QC2LE')
      *---------------------------------------------------------------------------------------
     Fxmlinput  if   f  112        disk    usropn                               uploaded text
     Fqxxxsrc   o    f  112        disk    usropn                               parsed out
      *--------------------------------------------------------------------
      * create parm prototypes
      *--------------------------------------------------------------------
      *  Tokenize String
     D strtok          PR              *          extproc('strtok')
     D  i_string                       *   value  options(*string)
     D  i_token                        *   value  options(*string)
      * retrieve member description
     D qusrmbrd        PR                  ExtPgm('QUSRMBRD')                   MEMBER DESCRIPTION
     D  o_rcvVar                  32767a          options(*varsize)             RECEIVER
     D  i_lenRcvVar                  10i 0 const                                LENGTH OF RECVR
     D  i_format                      8    const                                UPLOAD TYPE
     D  i_qFile                      20    const                                FILE   LIB
     D  i_mbr                        10    const                                MEMBER NAME
     D  i_ovverride                   1    const                                PROCESS OVERIDE
     D  io_errCode                32767a          options(*varsize)             ERROR CODE
      * retrieve object description
     D QUSROBJD...
     D                 PR                         extpgm('QUSROBJD')
     D  o_rcvVar                  65535A          options(*varsize)
     D  i_lenRcvVar                  10I 0 const
     D  i_format                      8A   const
     D  i_qObj                       20A   const
     D  i_type                       10A   const
     D  io_errCode                65535A          options(*nopass: *varsize)    | OptGrp 1
      * send program message
     D qmhsndpm        PR                  ExtPgm('QMHSNDPM')                   SEND MESSAGES
     D  i_msgID                       7a   const                                ID
     D  i_qMsgF                      20a   const                                FILE
     D  i_msgText                 32767a   const  options(*varsize)             TEXT
     D  i_lenMsgText                 10i 0 const                                LENGTH
     D  i_msgType                    10a   const                                TYPE
     D  i_callStackE                 10a   const                                STACK ENTRY
     D  i_callStackC                 10i 0 const                                STACK COUNTER
     D  i_msgKey                      4a   const                                KEY
     D  io_errCode                32767a          options(*varsize)             ERROR CODE
      * execute cl command
     D  qcmdexc        PR                  ExtPgm('QCMDEXC')
     D  i_cmd                        50a   Const
     D  i_lenCmd                     15p 5 Const
      *  Allocate Environment Handle
     D SQLAllocEnv...
     D                 PR                         extproc('SQLAllocEnv')
     D                                     like(SQLRETURN_t )
     D  o_phenv                        *   value
      *  Allocate Connection Handle
     D SQLAllocConnect...
     D                 PR                         extproc('SQLAllocConnect')
     D                                     like(SQLRETURN_t )
     D  i_henv                             value  like(SQLHENV_t   )
     D  o_phdbc                        *   value
      *  Connect to a Data Source
     D SQLConnect...
     D                 PR                         extproc('SQLConnect')
     D                                     like(SQLRETURN_t )
     D  i_hdbc                             value  like(SQLHDBC_t   )
     D  i_szDSN                        *   value  options(*string)
     D  i_cbDSN                            value  like(SQLSMALLINT_t)
     D  i_szUID                        *   value  options(*string)
     D  i_cbUID                            value  like(SQLSMALLINT_t)
     D  i_szAuthStr                    *   value  options(*string)
     D  i_cbAuthStr                        value  like(SQLSMALLINT_t)
      *  Set Connection Option
     D SQLSetConnectOption...
     D                 PR                         extproc('SQLSetConnectOption')
     D                                     like(SQLRETURN_t )
     D  i_hdbc                             value  like(SQLHDBC_t   )
     D  i_fOption                          value  like(SQLSMALLINT_t)
     D  i_vParam                           value  like(SQLPOINTER_t )
      *  Allocate a Statement Handle
     D SQLAllocStmt...
     D                 PR                         extproc('SQLAllocStmt')
     D                                     like(SQLRETURN_t )
     D  i_hdbc                             value  like(SQLHDBC_t   )
     D  o_phstmt                       *   value
      *  Execute a Statement Directly
     D SQLExecDirect...
     D                 PR                         extproc('SQLExecDirect')
     D                                     like(SQLRETURN_t )
     D  i_hstmt                            value  like(SQLHSTMT_t  )
     D  i_szSqlStr                     *   value  options(*string)
     D  i_cbSqlStr                         value  like(SQLINTEGER_t)
      *  Free (or Reset) a Statement Handle
     D SQLFreeStmt...
     D                 PR                         extproc('SQLFreeStmt')
     D                                     like(SQLRETURN_t )
     D  i_hstmt                            value  like(SQLHSTMT_t  )
     D  i_fOption                          value  like(SQLSMALLINT_t)
      *  Disconnect from a Data Source
     D SQLDisconnect...
     D                 PR                         extproc('SQLDisconnect')
     D                                     like(SQLRETURN_t )
     D  i_hdbc                             value  like(SQLHDBC_t   )
      *  Free Connection Handle
     D SQLFreeConnect...
     D                 PR                         extproc('SQLFreeConnect')
     D                                     like(SQLRETURN_t )
     D  i_hdbc                             value  like(SQLHDBC_t   )
      *  Free Environment Handle
     D SQLFreeEnv...
     D                 PR                         extproc('SQLFreeEnv')
     D                                     like(SQLRETURN_t )
     D  i_henv                             value  like(SQLHENV_t   )
      *--------------------------------------------------------------------
     D long_t          S             10I 0                    based(pDummy)
     D short_t         S              5I 0                    based(pDummy)
      *
     D SQLINTEGER_t    S                   like(long_t      ) based(pDummy)
     D SQLSMALLINT_t   S                   like(short_t     ) based(pDummy)
      *
     D PTR_t           S               *                      based(pDummy)
     D SQLPOINTER_t    S                   like(PTR_t       ) based(pDummy)
     D HENV_t          S                   like(long_t      ) based(pDummy)
     D HDBC_t          S                   like(long_t      ) based(pDummy)
     D HSTMT_t         S                   like(long_t      ) based(pDummy)
     D RETCODE_t       S                   like(SQLINTEGER_t) based(pDummy)
      *
     D SQLHENV_t       S                   like(HENV_t      ) based(pDummy)
     D SQLHDBC_t       S                   like(HDBC_t      ) based(pDummy)
     D SQLHSTMT_t      S                   like(HSTMT_t     ) based(pDummy)
     D SQLRETURN_t     S                   like(RETCODE_t   ) based(pDummy)
      *
     D retCode         S                   like(SQLRETURN_t) inz
     D hdbc            S                   like(SQLHDBC_t  ) inz
     D hstmt           S                   like(SQLHSTMT_t ) inz
     D henv            S                   like(SQLHENV_t  ) inz
     D sqlInit         S              1A                     inz(*off)
     D cOptVal         S             10I 0                   inz
      *
     D SQL_NTS         C                   const( -3)
     D SQL_COMMIT_NONE...
     D                 C                   const(  1)
     D SQL_ATTR_COMMIT...
     D                 C                   const(  0)
     D SQL_DROP        C                   const(  1)
      *--------------------------------------------------------------------
      * Read element
      *--------------------------------------------------------------------
     D readElement     PR                        like(bldexc)
     D  i_element                     9A   value varying
      *--------------------------------------------------------------------
      * Define function prototype to double quotes in a string
      *--------------------------------------------------------------------
     D dblQuotes       PR          2048A         varying
     D  i_string                   2048A   value varying
      *--------------------------------------------------------------------
      * Define function prototype to get attribute data from a string
      *--------------------------------------------------------------------
     D getAttrData...
     D                 PR          2000A          varying                       like(string_t)
     D  i_attr                       10a   value
     D  i_string                   2000A   value  varying                       like(string_t)
     D  i_default                  2000A   value  varying                       like(string_t)
      *--------------------------------------------------------------------
      * Define function prototype to check for a condition
      *--------------------------------------------------------------------
     D isCondition...
     D                 PR              n
     D  i_condList                 2000A   value
      *---------------------------------------------------------------------------------------
     D loadConditions...
     D                 PR                  dim(32) like(condition)
     D  i_conditions                128A   value
      *--------------------------------------------------------------------
     D getCurrentRelease...
     D                 PR            10A
      *--------------------------------------------------------------------
     D isRelease...
     D                 PR              n
     D  i_os_release                  6A   value
     D  i_release                    10A   value
      *--------------------------------------------------------------------
     D setTargetRelease...
     D                 PR          2000A          varying
     D  i_keyword                    10A   value  varying
     D  i_string                   2000A   value  varying
     D  i_value                      10A   value  varying
      *--------------------------------------------------------------------
     D setVariable...
     D                 PR
     D  i_fldName                    10A   value  varying
     D  i_value                      64A   value  varying
      *---------------------------------------------------------------------------------------------
     D getVarName...
     D                 PR            11a          varying
     D  i_bldexc                           value  like(bldexc)
     D  i_pos                        10i 0 value
      *---------------------------------------------------------------------------------------------
     D getVarValue...
     D                 PR            64a          varying
     D  i_name                       11a   value  varying
      *---------------------------------------------------------------------------------------------
     D uCase...
     D                 PR          2000A          varying
     D  i_string                   2000A   value  varying
      *--------------------------------------------------------------------
     D vrcvar          s            145
     D qm_msgid        s              7
     D qm_msgtxt       s            500
     D qm_msgq         s             10
     D qm_msgtyp       s             10
     D mbrname         s             10
     D mbrtype         s             10
     D mbrtext         s             50
     D srcfile         s             10
     D srclen          s              5
     D srclenN         s              5  0   inz(0)
     D srccssid        s              5
     D bldexc          s           2000
     D write_flag      s              1n   inz(*off)
     D srcSeqno        s              6s 2 inz(0)
     D aa              s              5u 0 inz(0)
     D ll              s              5u 0 inz(0)
     D qs              c                   ''''
     D qd              c                   '"'
     D errFLag         s              1    inz(*off)
     D cnd_msg         s             42
     D cnd_values      s            110
     D cnd_var         s             10
     D cnd_rtnVal      s             10
     D cnd_array       s                   dim(32) inz like(condition)
     D cnd_ptr         s             10i 0 inz
     D condition       s             10a
     D condList        s           2000a
     D release         s             10a
     D dltsplf         s             10a
     D objd_obj        s             10a
     D objd_lib        s             10a
     D objd_objtype    s             10a
     D objd_rtnlib     s             10a
     D objd0100        ds
     D  od_bytRet              1      4i 0
     D  od_bytAvl              5      8i 0
     D  od_name                9     18a
     D  od_lib                19     28a
     D  od_type               29     38a
     D  od_rtnLib             39     48a
     D fld_array       ds
     D  fld_x                        10i 0 inz
     D  fld_name                     11a   inz dim(64) varying
     D  fld_value                    64a   inz dim(64) varying
     D var_name        s             11a   inz varying
     D var_value       s             64a   inz varying
      * Error return code parm for APIs.
     D errCode         DS
     D  errCode_bytPrv...
     D                               10i 0 inz(%size(errCode))
     D  errCode_bytAvl...
     D                               10i 0 inz(0)
     D  errCode_excID...
     D                                7a   inz
     D  errCode_reserved...
     D                                1a   inz
     D  errCode_escData...
     D                              256a   inz
      * Optional parameters
     D OvrSrcFile      s                   like(i_OvrSrcFile) inz
     D isPreDefCond    s               N   inz(*off)
     D TgtRls          s                   like(i_TgtRls    ) inz
      *
      * Program status data structure.
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
      *--------------------------------------------------------------------
     Ixmlinput  ns
     I                                 13   21  xmltag1
     I                                 18   27  xmltag2
     I                                 13  112  xmlcode
      *--------------------------------------------------------------------
     C     *entry        plist
     C                   parm                    ParseSrcMbr      10            source member
     C                   parm                    ParseSrcFile     10            source file
     C                   parm                    ParseSrcLib      10            source lib
      *  optional parameters:
     C                   parm                    i_OvrSrcFile     10            override to src
     C                   parm                    i_Conditions    128            pre-def conditions
     C                   parm                    i_TgtRls         10            target release
      *
      *  get optional parameter: Overrride to Source File
     C                   if        %parms() >= 4
     C                   eval      OvrSrcFile = i_OvrSrcFile
     C                   else
     C                   eval      OvrSrcFile = ''
     C                   endif
      *
      *  get optional parameter: Conditions
     C                   if        %parms() >= 5
     C                   if        %subst(i_Conditions:1:32) <> ''
     C                   eval      cnd_array = loadConditions(i_Conditions)
     C                   eval      isPreDefCond = *on
     C                   else
     C                   eval      isPreDefCond = *off
     C                   endif
     C                   endif
      *
      *  get optional parameter: Target Release
     C                   if        %parms() >= 6
     C                   eval      TgtRls = i_TgtRls
     C                   else
     C                   eval      TgtRls = getCurrentRelease()
     C                   endif
      *
     C                   exsr      srValidate                                   make sure exist
      *
      * Set user selected library *first for remainder of program
     C                   eval      bldexc = 'RMVLIBLE LIB('+
     C                             %trimr(ParseSrcLib) + ')'
     C                   callp(e)  qcmdexc(bldexc:%len(%trimr(bldexc)))
      *
     C                   eval      bldexc = 'ADDLIBLE LIB('+
     C                             %trimr(ParseSrcLib) + ') POSITION(*FIRST)'
     C                   callp(e)  qcmdexc(bldexc:%len(%trimr(bldexc)))
      *
      *       CPF2103 - Library &1 already exists in library list.
     C                   if        %error and sds_msgID <> 'CPF2103'
     C                   eval      qm_msgtxt = '0000 ' + sds_msgText
     C                   exsr      srKill
     C                   endif
      *
      * Set variable &TOLIB
     C                   callp     setVariable('tolib': ParseSrcLib)
      *
      * Set variable &TGTRLS
     C                   callp     setVariable('tgtrls': TgtRls)
      *
      * Set variable &XMLFILE
     C                   callp     setVariable('xmlfile': ParseSrcFile)
      *
      * Set variable &XMLLIB
     C                   callp     setVariable('xmllib': ParseSrcFile)
      *
      * Set variable &XMLMBR
     C                   callp     setVariable('xmlmbr': ParseSrcFile)
      *
      * Override Input file to uploaded text file
     C                   eval      bldexc = 'OVRDBF FILE(XMLINPUT) TOFILE(' +
     C                             %trimr(ParseSrcLib)+'/'+
     C                             %trimr(ParseSrcFile) + ') MBR(' +
     C                             %trimr(ParseSrcMbr) + ')'
     C                   callp     qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   open      xmlinput
     C                   read      xmlinput
     C                   dow       not %eof
      * write records to outfile if flag is on
     C                   select
     C                   when      write_flag = *on
     C                   if        xmltag2<>'</copysrc>'
     C                   eval      srcSeqno=srcSeqno+1
     C                   except    write_one
     C                   else
     C                   eval      write_flag=*off
     C                   close     qxxxsrc
     C                   endif
      *
      * Extract values based on xml tags.
     C                   when      xmltag1 = 'mbrname ='
     C                   eval      mbrname = %subst(xmlcode:13:10)
     C                   when      xmltag1 = 'mbrtype ='
     C                   eval      mbrtype =%subst(xmlcode:13:10)
     C                   when      xmltag1 = 'mbrtext ='
     C                   eval      mbrtext =dblQuotes(%subst(xmlcode:13:50))
     C                   when      xmltag1 = 'srcfile ='
     C                   if        OvrSrcFile <> ''
     C                   eval      srcfile =OvrSrcFile
     C                   else
     C                   eval      srcfile =%subst(xmlcode:13:10)
     C                   endif
     C                   when      xmltag1 = 'srclen  ='
     C                   eval      srclen  =%subst(xmlcode:13:5)
     C                   when      xmltag1 = 'srccssid='
     C                   eval      srccssid=%subst(xmlcode:13:5)
      *--------------------------------------------------------------------
      * Start of data to copy.  Create source files/mbrs as required.
      *--------------------------------------------------------------------
     C                   when      xmltag1='<copysrc>'
     C                   move      srclen        srclenN
      * crtsrcpf
     C                   eval      bldexc = 'CRTSRCPF FILE(' +
     C                             %trimr(ParseSrcLib)+'/'+
     C                             %trimr(srcfile) + ') RCDLEN(' +
     C                             srclen + ') CCSID(' +
     C                             srccssid + ')'
     C                   callp(e)  qcmdexc(bldexc:%len(%trimr(bldexc)))
      * addpfm
     C                   eval      bldexc = 'ADDPFM   FILE(' +
     C                             %trimr(ParseSrcLib)+'/'+
     C                             %trimr(srcfile) + ') MBR(' +
     C                             %trimr(mbrname) + ') SRCTYPE(' +
     C                             %trimr(mbrtype) + ') TEXT(' +
     C                             qs+%trimr(mbrtext)+qs + ')'
     C                   callp(e)  qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   if        %error
      * chgpfm
     C                   eval      bldexc = 'CHGPFM   FILE(' +
     C                             %trimr(ParseSrcLib)+'/'+
     C                             %trimr(srcfile) + ') MBR(' +
     C                             %trimr(mbrname) + ') TEXT(' +
     C                             qs+%trimr(mbrtext)+qs + ')'
     C                   callp     qcmdexc(bldexc:%len(%trimr(bldexc)))
      * clr mbr
     C                   eval      bldexc = 'CLRPFM   FILE(' +
     C                             %trimr(ParseSrcLib)+'/'+
     C                             %trimr(srcfile) + ') MBR(' +
     C                             %trimr(mbrname) + ')'
     C                   callp     qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   endif
      * ovr to outfile mbr
     C                   eval      bldexc = 'OVRDBF QXXXSRC ' +
     C                             %trimr(ParseSrcLib) + '/' +
     C                             %trimr(srcfile) + ' ' +
     C                             mbrname
     C                   callp     qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   clear                   srcSeqno
     C                   open      qxxxsrc
     C                   eval      write_flag = *on
      *--------------------------------------------------------------------
      * Compile statement.  Read next record and execute it.
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<compile '
     C                   eval      condList= getAttrData('condition':xmlcode:'')
     C                   read      xmlinput
     C                   eval      bldexc = readElement('compile')
     C                   if        isCondition(condList)
     C                   exsr      RplVars
     C                   exsr      SetTgtRls
     C                   callp     qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   endif
      *--------------------------------------------------------------------
      * qcmdexc statement. Build statement from each record between start
      * and stop tags.  When stop tag is found, execute statement.
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<qcmdexc '
     C                   eval      condList = getAttrData('condition'
     C                                                    :xmlcode:'')
     C                   eval      release  = getAttrData('release'
     C                                                    :xmlcode:'*CURRENT')
     C                   eval      dltsplf  = getAttrData('dltsplf'
     C                                                    :xmlcode:'*NONE')
     C                   read      xmlinput
     C                   eval      bldexc = readElement('qcmdexc')
     C                   if        isCondition(condList) and
     C                             isRelease(tgtRls: release)
     C                   exsr      RplVars
     C                   exsr      SetTgtRls
     C                   if        %subst(bldexc: 1: 3) = 'DLT'
     C                   callp (e) qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   else
     C                   callp (e) qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   if        %error()
     C                   eval      qm_msgtxt = '0000 Failed to execute: '+bldexc
     C                   exsr      srKill
     C                   endif
     C                   if        dltsplf <> '' and dltsplf <> '*NONE'
     C                   eval      bldexc = 'DLTSPLF FILE(' + dltsplf +
     C                                      ') JOB(*) SPLNBR(*LAST)'
     C                   callp (e) qcmdexc(bldexc:%len(%trimr(bldexc)))
     C                   endif
     C                   endif
     C                   endif
      *--------------------------------------------------------------------
      * SQL statement. Build statement from each record between start
      * and stop tags.  When stop tag is found, execute SQL statement.
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<execsql '
     C                   eval      condList = getAttrData('condition'
     C                                                    :xmlcode:'')
     C                   read      xmlinput
     C                   eval      bldexc = readElement('execsql')
     C                   if        isCondition(condList)
     C                   exsr      RplVars
     C                   exsr      srSQLExecute
     C                   endif
      *--------------------------------------------------------------------
      * Send messages to user as program executes
      * Extract message ID, Message Type, from <sendmsg>
      * read a record and get the single line of message text.
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<sendmsg '
     C                   eval      qm_msgid = %subst(xmlcode:22:7)
     C                   eval      qm_msgtyp = %subst(xmlcode:46:10)
     C                   read      xmlinput
     C                   eval      qm_msgq   = '*EXT   '
     C                   eval      qm_msgtxt = xmlcode
     C                   exsr      srSndMessage
      *--------------------------------------------------------------------
      * rtvobjd statement. retrieve object description of the specified
      * object. Store attributes in specified fields.
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<rtvobjd '
     C                   eval      condList = getAttrData('condition'
     C                                                    :xmlcode:'')
     C                   eval      bldexc = readElement('rtvobjd')
     C                   eval      objd_obj    =getAttrData('obj'    :bldexc:'')
     C                   eval      objd_lib    =getAttrData('lib'    :bldexc:'')
     C                   eval      objd_objtype=getAttrData('objtype':bldexc:'')
     C                   eval      objd_rtnlib =getAttrData('rtnlib' :bldexc:'')
     C                   if        isCondition(condList)
     C                   exsr      srRtvObjD
     C                   endif
      *--------------------------------------------------------------------
      * chgvar statement.
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<chgvar  '
     C                   eval      condList = getAttrData('condition'
     C                                                    :xmlcode:'')
     C                   eval      bldexc = readElement('chgvar')
     C                   eval      var_name  = getAttrData('var'    :bldexc:'')
     C                   eval      var_value = getAttrData('value'  :bldexc:'')
     C                   if        isCondition(condList)
     C                   exsr      srChgVar
     C                   endif
      *--------------------------------------------------------------------
      * Query condition
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<qrycond '
     C                   eval      bldexc = readElement('qrycond')
     C                   eval      cnd_msg = getAttrData('msg'   : bldexc: '')
     C                   eval      cnd_values = getAttrData('values': bldexc:'')
     C                   eval      cnd_var = getAttrData('var': bldexc: '*NONE')
     C                   exsr      srQueryCond
     C                   endsl
      *
     C                   read      xmlinput
     C                   enddo
      *
     C                   exsr      srSQLEnd
     C                   eval      *inlr=*on
     C                   return
      *--------------------------------------------------------------------
      * Replace variable names with their associated values.
      *--------------------------------------------------------------------
     C     RplVars       begsr
     C                   eval      aa=%scan('&':bldexc)
     C                   dow       aa>0
     C                   eval      var_name=getVarName(bldexc:aa)
     C                   eval      var_value=getVarValue(var_name)
     C                   eval      bldexc=%replace(var_value:bldexc:aa
     C                                             :%len(var_name))
     C                   eval      aa=%scan('&':bldexc)
     C                   enddo
     C                   endsr
      *--------------------------------------------------------------------
      * Sets the target release according to the optional parameter
      * i_TgtRls.
      *--------------------------------------------------------------------
     C     SetTgtRls     begsr
     C                   if        TgtRls = getCurrentRelease()
     C                   leavesr
     C                   endif
     C                   eval      bldexc =
     C                                setTargetRelease('TGTRLS': bldexc: TgtRls)
     C                   endsr
      *--------------------------------------------------------------------
      * Check of file, lib, member exist.
      *--------------------------------------------------------------------
     C     srValidate    begsr
     C                   callp     QUSRMBRD(
     C                             vrcvar:
     C                             145:
     C                             'MBRD0100':
     C                             ParseSrcFile + ParseSrcLib:
     C                             ParseSrcMbr:
     C                             '0':
     C                             errCode)
      *   --------------------------------------------------------------------------------
      *   If error occurred on call, send appropriate message back to user.
      *   ---------------------------------------------------------------------------------
     C                   if        errCode_bytAvl <> 0                          error occurred
     C                   select
      * lib not found
     C                   when      errCode_excID = 'CPF9810'
     C                   eval      qm_msgtxt = '0000 Library ' +
     C                             %trimr(ParseSrcLib) + ' was not found.'
      * src file not found
     C                   when      errCode_excID = 'CPF9812'
     C                   eval      qm_msgtxt = '0000 Source file ' +
     C                             %trimr(ParseSrcFile)+' was not found in ' +
     C                             %trimr(ParseSrcLib) + '.'
      * member not found
     C                   when      errCode_excID = 'CPF9815'
     C                   eval      qm_msgtxt = '0000 Member ' +
     C                             %trimr(ParseSrcMbr)+' was not found in ' +
     C                             %trimr(ParseSrcLib)+'/'+ %trimr(ParseSrcFile)
      * unexpected
     C                   other
     C                   eval      qm_msgtxt = '0000 Unexpected message ' +
     C                             errCode_excID + ' received. '
     C                   endsl
      * send message
     C                   exsr      srKill
     C                   eval      *inlr=*on
     C                   return
     C                   endif
     C                   endsr
      *--------------------------------------------------------------------
      * kill application
      *--------------------------------------------------------------------
     C     srKill        begsr
     C                   eval      qm_msgid  = 'CPD0006'
     C                   eval      qm_msgtyp = '*DIAG'
     C                   eval      qm_msgq   = '*CTLBDY'
     C                   exsr      srSndMessage
     C                   eval      qm_msgtxt = *blanks
     C                   eval      qm_msgid  = 'CPF0002'
     C                   eval      qm_msgtyp = '*ESCAPE'
     C                   exsr      srSndMessage
     C                   endsr
      *--------------------------------------------------------------------
      * call send program message api
      *--------------------------------------------------------------------
     C     srSndMessage  begsr
     C                   callp     QMHSNDPM(
     C                             qm_msgid:
     C                             'QCPFMSG   *LIBL     ':
     C                             qm_msgtxt:
     C                             %size(qm_msgtxt):
     C                             qm_msgtyp:
     C                             qm_msgq:
     C                             1:
     C                             '    ':
     C                             errCode)
     C                   endsr
      *--------------------------------------------------------------------
      * retrieve object description and store attributes
      *--------------------------------------------------------------------
     C     srRtvObjD     begsr
     C                   callp     QUSROBJD(objd0100
     C                                      : %size(objd0100)
     C                                      : 'OBJD0100'
     C                                      : objd_obj + objd_lib
     C                                      : objd_objtype
     C                                      : errCode)
     C                   if        errCode_bytAvl <> 0                          error occurred
     C                   eval      qm_msgtxt = '0000 Failed to retrieve +
     C                             object description of object ' +
     C                             %trim(objd_lib) + '/' + %trim(objd_obj) +
     C                             ' type ' + %trim(objd_objtype) + '.'
      * send message
     C                   exsr      srKill
     C                   else
     C                   callp     setVariable(objd_rtnlib: od_rtnlib)
     C                   endif
     C                   endsr
      *--------------------------------------------------------------------
      * change variable
      *--------------------------------------------------------------------
     C     srChgVar      begsr
     C                   callp     setVariable(var_name: var_value)
     C                   endsr
      *--------------------------------------------------------------------
      * execute SQL statement.
      *--------------------------------------------------------------------
     C     srSQLExecute  begsr
     C                   exsr      srSQLInit
     C                   Eval      retCode = SQLExecDirect(hstmt    :
     C                                                     bldexc   :
     C                                                     SQL_NTS  )
     C                   endsr
      *--------------------------------------------------------------------
      * query condition.
      *--------------------------------------------------------------------
     C     srQueryCond   begsr
     C                   if        isPreDefCond = *off
     C                   eval      cnd_values = uCase(cnd_values)
     C                   dou       (%scan(cnd_rtnVal: cnd_values) > 0) and
     C                             (cnd_rtnval <> ''                 )
     C                   eval      cnd_rtnval = ' '
     C     cnd_msg       dsply                   cnd_rtnval
     C                   eval      cnd_rtnVal = uCase(cnd_rtnVal)
     C                   enddo
     C                   eval      cnd_ptr = cnd_ptr + 1
     C                   eval      cnd_array(cnd_ptr) = cnd_rtnVal
     C                   endif
     C                   if        (cnd_var <> '*NONE')
     C                   callp     setVariable(cnd_var: cnd_rtnval)
     C                   endif
     C                   endsr
      *--------------------------------------------------------------------
      * initialize SQL.
      *--------------------------------------------------------------------
     C     srSQLInit     begsr
      *
     C                   if        sqlInit = *off
     C                   Eval      retCode = SQLAllocEnv(%addr(henv))
     C                   Eval      retCode = SQLAllocConnect(henv: %addr(hdbc))
     C                   Eval      retCode = SQLConnect(hdbc      :
     C                                                  '*LOCAL'  :
     C                                                  SQL_NTS   :
     C                                                  *null     :
     C                                                  SQL_NTS   :
     C                                                  *null     :
     C                                                  SQL_NTS   )
     C                   Eval      cOptVal = SQL_COMMIT_NONE
     C                   Eval      retCode = SQLSetConnectOption(hdbc          :
     C                                                          SQL_ATTR_COMMIT:
     C                                                          %addr(cOptVal) )
     C                   Eval      retCode = SQLAllocStmt(hdbc       :
     C                                                  %addr(hstmt) )
     C                   eval      sqlInit = *on
     C                   endif
     C                   endsr
      *--------------------------------------------------------------------
      * end SQL.
      *--------------------------------------------------------------------
     C     srSQLEnd      begsr
     C                   if        sqlInit = *on
     C                   Eval      retCode = SQLFreeStmt(hstmt    :
     C                                                   SQL_DROP )
     C                   Eval      retCode = SQLDisconnect(hdbc)
     C                   Eval      retCode = SQLFreeConnect(hdbc)
     C                   Eval      retCode = SQLFreeEnv(henv)
     C                   eval      sqlInit = *off
     C                   endif
     C                   endsr
      *--------------------------------------------------------------------
      * error handler
      *--------------------------------------------------------------------
     C     *pssr         begsr
     C                   if        errFLag = *off
     C                   eval      errFlag = *on
     C                   exsr      srSQLEnd
     C                   endif
     C                   endsr     '*CANCL'
     Oqxxxsrc   e            write_one
     O                       srcSeqno             6
     O                                           12 '000000'
     O                       xmlcode            112
      *--------------------------------------------------------------------
      * Read element
      *--------------------------------------------------------------------
     P readElement...
     P                 B
     D                 PI                        like(bldexc)
     D  i_element                     9A   value varying
      *
     D i               S             10I 0 inz
     D value           S                   like(bldexc ) inz
     D endTag          S                   like(xmlTag2) inz
      *
     C                   eval      i = 1
     C                   eval      endTag = '</' + i_element + '>'
     C                   dow       xmltag2 <> endTag
     C                   eval      %subst(value: i: %len(xmlcode)) = xmlcode
     C                   eval      i = i + %len(xmlcode)
     C                   read      xmlinput
     C                   enddo
      *
     C                   Return    value
      *
     P                 E
      *--------------------------------------------------------------------
      * Double quotes
      *--------------------------------------------------------------------
     P dblQuotes...
     P                 B
     D                 PI          2048A         varying
     D  i_string                   2048A   value varying
      *
     D x               S             10I 0         inz
     D string          S           2048A   varying inz
      *
     C                   For       x = 1 to %len(i_string)
     C                   Eval      string = string + %subst(i_string: x:1)
     C                   If        %subst(i_string: x : 1) = qs
     C                   Eval      string = string + qs
     C                   Endif
     C                   Endfor
      *
     C                   Return    string
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Get Attribute Data from String
      *---------------------------------------------------------------------------------------------
     P getAttrData...
     P                 B
     D                 PI          2000A          varying                       like(string_t)
     D  i_attr                       10a   value
     D  i_string                   2000A   value  varying                       like(string_t)
     D  i_default                  2000A   value  varying                       like(string_t)
      *
      *  return value
     D attrData        S           2000A   varying inz                          like(string_t)
      *
      *  local fields
     D attr            S             20a   varying inz
     D lenAttr         S             10i 0 inz
     D aa              S             10i 0 inz
     D cc              S             10i 0 inz
      *
     D Qd              C                   const('"')
      *-------------------------------------------------------------------*
      *
      *  find the keyword
     C                   eval      attr = %trim(i_attr) + '=' + Qd
      *
     C                   eval      aa   = %scan(attr: i_string)
     C                   if        aa = 0
     C                   return    i_default
     C                   endif
      *
     C                   eval      aa   = aa + %len(attr)
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
      *---------------------------------------------------------------------------------------------
      *  Load condition array
      *---------------------------------------------------------------------------------------------
     P loadConditions...
     P                 B
     D                 PI                  dim(32) like(condition)
     D  i_conditions                128A   value
      *
      *  return value
     D cnd_array       s                   dim(32) inz like(condition)
     D pValue          s               *   inz
     D x               s             10i 0 inz
     D i               s             10i 0 inz
     D cnd_value       s            128a   varying
     D var_name        s             64a   varying
     D var_value       s             64a   varying
      *-------------------------------------------------------------------*
      /FREE

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
      /END-FREE
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Check for a condition
      *---------------------------------------------------------------------------------------------
     P isCondition...
     P                 B
     D                 PI              n
     D  i_condList                 2000A   value
      *
      *  return value
     D isCondition     S               n   inz
     D pValue          S               *   inz
     D aCondition      S             10a   inz
      *-------------------------------------------------------------------*
      *
     C                   eval      i_condList = uCase(i_condList)
      *
     C                   if        (i_condList = '*NONE')  or
     C                             (i_condList = ''     )
     C                   eval      *in01 = *on
     C                   else
      *
     C                   eval      pValue = strtok(i_condList: ' ')
     C                   dow       pValue <> *null
     C                   eval      aCondition = %str(pValue)
     C     aCondition    lookup    cnd_array                              01
     C                   if        not *in01
     C                   leave
     C                   endif
     C                   eval      pValue = strtok(*null     : ' ')
     C                   enddo
      *
     C                   endif
      *
     C                   if        *in01
     C                   eval      isCondition = *on
     C                   else
     C                   eval      isCondition = *off
     C                   endif
      *
     C                   Return    isCondition
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Get the current release level of the operation system
      *---------------------------------------------------------------------------------------------
     P getCurrentRelease...
     P                 B
     D                 PI            10A
      *
      *  QSZRTVPR API
     D QSZRTVPR...
     D                 PR                  extpgm('QSZRTVPR')
     D  o_rcvVar                  65535A          options(*varsize)
     D  i_lenRcvVar                  10I 0 const
     D  i_format                      8A   const
     D  o_prodInf                 65535A   const  options(*varsize)
     D  io_errCode                65535A          options(*varsize)
      *
     D prdi0100        DS                  qualified
     D  productID              1      7A   inz('*OPSYS')
     D  releaseLvl             8     13A   inz('*CUR'  )
     D  productOpt            14     17A   inz('0000'  )
     D  loadID                18     27A   inz('*CODE' )
      *  Shortened!:
     D prdr0100        DS                  qualified
     D  bytRet                 1      4I 0
     D  bytAvl                 5      8I 0
     D  reserved_1             9     12I 0
     D  productID             13     19A
     D  releaseLvl            20     25A
      *  API error code
     D errCode         DS
     D  bytPrv                       10i 0 inz(0)
     D  bytAvl                       10i 0 inz(0)
      *-------------------------------------------------------------------*
      *
     C                   Callp     QSZRTVPR(prdr0100: %size(prdr0100):
     C                                      'PRDR0100': prdi0100: errCode)
     C                   Return    prdr0100.releaseLvl
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Check the release level
      *---------------------------------------------------------------------------------------------
     P isRelease...
     P                 B
     D                 PI              n
     D  i_os_release                  6A   value
     D  i_release                    10A   value
      *
      *  return value
     D isRelease       S               n   inz(*off)
      *  Release
     D release         DS
     D  r_operator             1      3a
     D  r_space                4      4a
     D  r_level                5     10a
      *-------------------------------------------------------------------*
      *
     C                   If        i_release = '*CURRENT'
     C                   Eval      isRelease = *on
     C                   Else
     C                   Eval      release = i_release
     C                   Select
     C                   When      r_operator = '*LT' and
     C                             i_os_release < r_level
     C                   Eval      isRelease = *on
     C                   When      r_operator = '*EQ' and
     C                             i_os_release = r_level
     C                   Eval      isRelease = *on
     C                   When      r_operator = '*GT' and
     C                             i_os_release > r_level
     C                   Eval      isRelease = *on
     C                   When      r_operator = '*LE' and
     C                             i_os_release <= r_level
     C                   Eval      isRelease = *on
     C                   When      r_operator = '*GE' and
     C                             i_os_release >= r_level
     C                   Eval      isRelease = *on
     C                   Other
     C                   Eval      isRelease = *off
     C                   Endsl
     C                   Endif
      *
     C                   Return    isRelease
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Replaces the value of a given keyword.
      *---------------------------------------------------------------------------------------------
     P setTargetRelease...
     P                 B
     D                 PI          2000A          varying
     D  i_keyword                    10A   value  varying
     D  i_string                   2000A   value  varying
     D  i_value                      10A   value  varying
      *
      *  return value
     D string          S           2000A   varying inz
      *
      *  helper fields
     D x               S             10I 0 inz
     D l               S             10I 0 inz
     D tmpKeyword      S                   like(i_keyword) inz
     D tmpString       S                   like(i_string ) inz
     D tmpCmd          S             10A   inz
      *-------------------------------------------------------------------*
      /FREE

         tmpKeyword = uCase(%trimR(i_keyword));
         tmpString  = uCase(%trimR(i_string ));
         x = %scan(' ': tmpString);
         if x = 0;
            return i_string;
         endif;
         tmpCmd = %subst(tmpString: 1: x);
         if tmpCmd <> 'CRTRPGMOD' and
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
            tmpCmd <> 'CRTSRVPGM' ;
            return i_string;
         endif;
         x = %scan(tmpKeyword + '(': tmpString);
         if x = 0;
            return %trimR(i_string) +
                   ' ' + tmpKeyword + '(' + %trimR(i_value) + ')';
         endif;
         l = %scan(')': tmpString: x + %len(i_keyword) + 1);
         if l = 0;
            return i_string;
         endif;
         l = l - x + 1;
         string = %replace(tmpKeyword + '(' + %trimR(i_value) + ')'
                           : i_string: x: l);
         Return string;

      /END-FREE
     P                 E
      *---------------------------------------------------------------------------------------------
      *  Store field value.
      *---------------------------------------------------------------------------------------------
     P setVariable...
     P                 B
     D                 PI
     D  i_fldName                    10A   value  varying
     D  i_value                      64A   value  varying
     D i               s             10I 0 inz
      *-------------------------------------------------------------------*
      /FREE

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

      /END-FREE
     P                 E
      *---------------------------------------------------------------------------------------------
      *  get variable name from statement.
      *---------------------------------------------------------------------------------------------
     P getVarName...
     P                 B
     D                 PI            11a          varying
     D  i_bldexc                           value  like(bldexc)
     D  i_pos                        10i 0 value
     D name            s             11a   varying inz
     D CHARS           c                   '&ABCDEFGHIJKLMNOPQRSTUVWXYZ+
     D                                      abcdefghijklmnopqrstuvwxyz+
     D                                      1234567890_'
      *-------------------------------------------------------------------*
      /FREE

         dow (i_pos<=%len(i_bldexc) and
              %check(CHARS:%subst(i_bldexc:i_pos:1))=0);
            name = name+%subst(i_bldexc:i_pos:1);
            i_pos=i_pos+1;
         enddo;

         return name;

      /END-FREE
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  get variable value.
      *---------------------------------------------------------------------------------------------
     P getVarValue...
     P                 B
     D                 PI            64a          varying
     D  i_name                       11a   value  varying
     D i               s             10i 0 inz
     D value           s             64a   varying inz('?')
      *-------------------------------------------------------------------*
      /FREE

         for i=1 to fld_x;
            if (ucase(fld_name(i))=uCase(i_name));
               value=%trimR(fld_value(i));
               leave;
            endif;
         endfor;

         return value;

      /END-FREE
      *
     P                 E
      *---------------------------------------------------------------------------------------------
      *  convert to upper case
      *---------------------------------------------------------------------------------------------
     P uCase...
     P                 B
     D                 PI          2000A          varying
     D  i_string                   2000A   value  varying
     D uCase           s           2000A   inz varying
     D LC              C                   const('abcdefghijklmnopqrstuvwxyz')
     D UC              C                   CONST('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
      *-------------------------------------------------------------------*
      /FREE

         uCase = %xlate(LC:UC:i_string);

         return uCase;

      /END-FREE
     P                 E
      * /// END   OF INSTALL PGM HERE   ****************************************** ///
      * /// do not copy past this point ///
