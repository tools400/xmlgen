      *%METADATA                                                       *
      * %TEXT Preview uploads before install                 jcr       *
      *%EMETADATA                                                      *
     H DFTACTGRP(*NO) ACTGRP(*CALLER)
      *---------------------------------------------------------------------------------------
      * Preview XML upload before install.
      * Copyright (C) 2001    Craig Rutledge    <craig_rutledge@mohawkind.com>
      *
      * This is a 'for your protection' program.  It is very strongly recommended you run
      * this program over any uploaded XMLGEN generated source before you commit to install.
      *
      * This subfile program will list the
      * 1. source members about to installed.
      * 2. source files that may be created.
      * 3. any commands that will be executed during installation.
      *
      * It is your responsibility to verify these operations performed during the
      * install are not inimical to your environment.
      *
      * If you are satisfied with the upload, press F10 to auto install.
      *
      *-----
      * This program is free software, you can redistribute it and/or modify it
      * under the terms of the GNU General Public License as published by
      * the Free Software Foundation.  See GNU General Public License for details
      *---------------------------------------------------------------------------------------------
      * >>PRE-COMPILER<<
      *   >>CRTCMD<< CRTBNDRPG    PGM(&LI/&OB) +
      *                           SRCFILE(&SL/&SF) SRCMBR(&SM);
      *   >>COMPILE<<
      *     >>PARM<< TRUNCNBR(*NO);
      *     >>PARM<< DBGVIEW(*LIST);
      *     >>PARM<< OPTION(*EVENTF);
      *   >>END-COMPILE<<
      *   >>EXECUTE<<
      * >>END-PRE-COMPILER<<
      *---------------------------------------------------------------------------------------
      /copy 'qxmlprev/copyright.rpgleinc'
      *
     Fxmlinput  if   f  112        disk
     Fxmlpreviedcf   e             workstn sfile(data1:rrn1)
     D String          s            500    varying
     D aa              s              5u 0 inz(0)
     D ll              s              5u 0 inz(0)
     D cc              s              5u 0 inz(0)
     D rrn1            s              5u 0
     D SequenceNum     s              3p 0
      *--------------------------------------------------------------------
     D main...
     D                 PR                  extpgm('XMLPREVIER')                 Input Parms
     D  i_smbr                       10A   const
     D  i_sfil                       10A   const
     D  i_slib                       10A   const
     D  i_usrsfil                    10A   const
     D  i_tgtrls                     10A   const
     D  i_action                      4A
      *    -------------------------------------------------------------
     D main...
     D                 PI                                                       Input Parms
     D  i_smbr                       10A   const
     D  i_sfil                       10A   const
     D  i_slib                       10A   const
     D  i_usrsfil                    10A   const
     D  i_tgtrls                     10A   const
     D  i_action                      4A
      *--------------------------------------------------------------------
     Ixmlinput  ns
     I                                 13   21  xmltag1
     I                                 13   29  xmlinstallpgm
     I                                 18   27  xmltag2
     I                                 13  112  xmlcode
      *--------------------------------------------------------------------
     C                   eval      i_action='N'                                 F10 ='Y'
      *
     C                   read      xmlinput
     C                   dow       not %eof
      *
     C                   select
      * determine if install_program source is included in text
     C                   when      xmlinstallpgm ='<install_program>'
     C                   eval      *in40=*on                                    enable install
      *
      * Extract values based on xml tags and load to subfile record(s)
     C                   when      xmltag1 = 'mbrname ='
     C                   add       1             SequenceNum
     C                   eval      xdata=%trimr(%editc(SequenceNum:'4'))
     C                   eval      %subst(xdata:5:3)='mbr'
     C                   eval      %subst(xdata:9:10) =
     C                                       %subst(xmlcode:13:10)
      *
     C                   when      xmltag1 = 'mbrtype ='
     C                   eval      %subst(xdata:20:10) =
     C                                      %subst(xmlcode:13:10)
      *
     C                   when      xmltag1 = 'mbrtext ='
     C                   eval      %subst(xdata:43) =
     C                                      %subst(xmlcode:13:50)
      *
     C                   when      xmltag1 = 'srcfile ='
     C                   if        i_usrsfil='*DEFAULTS '                       xmlpreview ove
     C                   eval      %subst(xdata:31:10) = %subst(xmlcode:13:10)
     C                   else
     C                   eval      %subst(xdata:31:10) = i_usrsfil
     C                   endif
      *
     C                   when      xmltag1 = 'srccssid='
     C                   eval      rrn1=rrn1+1
     C                   write     data1                                        LOAD SUBFILE
      *
      *--------------------------------------------------------------------
      * qcmdexc statement. Build statement from each record between start
      * and stop tags.  When stop tag is found, process into subfile records
      *--------------------------------------------------------------------
     C                   when      xmltag1 = '<qcmdexc>'
     C                   clear                   string
     C                   eval      aa=1
     C                   read      xmlinput
     C                   dow       xmltag2<>'</qcmdexc>'
     C                   eval      %len(string)=%len(string)+100
     C                   eval      %subst(string:aa:100)=xmlcode
     C                   eval      aa=aa+100
     C                   read      xmlinput
     C                   enddo
     C                   exsr      TolibToken
     C                   exsr      srParseCmd
     C                   endsl
      *
     C                   read      xmlinput
     C                   enddo
      *
      *----------------------------------------------------------------
      * Show subfile.  F3/F12 = Exit   F10=Run Install
      *----------------------------------------------------------------
     C                   eval      *in01 = (rrn1>0)                             THERE ARE RECO
     C                   eval      *in02 = *on                                  DISPLAY CONTRL
     C                   dow       *inkc = *off
     C                   write     keys                                         GET USER RESPO
     C                   exfmt     contrl1                                      VIEW 1
     C                   select
     C                   when      *inkc or *inkl                               f3 or f12
     C                   leave
     C                   when      *inkj  and *in40                             F10=install
     C                   eval      i_action='Y'                                 CALL INSTALL
     C                   leave
     C                   endsl
     C                   enddo
     C                   eval      *inlr=*on
     C                   return
      *
      *--------------------------------------------------------------------
      * Replace &tolib (no matter how many times it is in the string)
      * with whatever library the user has selected at run time.
      *  Must replace create-from source files if user has selected override.
      *--------------------------------------------------------------------
     C     TolibToken    begsr
     C                   eval      aa=%scan('&tolib':string)
     C                   dow       aa>0
     C                   eval      string=%replace(%trimr(i_slib):string:
     C                             aa:6)
     C                   eval      aa=%scan('&tolib':string)
     C                   enddo
      *
     C                   if        i_usrsfil<>'*DEFAULTS '
     C                   eval      aa=%scan('SRCFILE(':string)
     C                   if        aa>0
     C                   eval      aa=%scan('/':string:aa)
     C                   if        aa>0
     C                   eval      ll=%scan(')':string:aa)
     C                   eval      string=%replace(%trimr(i_usrsfil):string:
     C                             aa+1:ll-(aa+1))
     C                   endif
     C                   endif
     C                   endif
      *
     C                   endsr
      *
      *---------------------------------------------------------------------------------------
      * write commands to subfile.
      *---------------------------------------------------------------------------------------
     C     srParseCmd    begsr
     C                   clear                   xdata
     C                   eval      rrn1=rrn1+1
     C                   write     data1                                        LOAD SUBFILE
     C                   add       1             SequenceNum
     C                   eval      xdata=%trimr(%editc(SequenceNum:'4'))
     C                   eval      %subst(xdata:5:3)='cmd'
      *
     C                   eval      aa=1
     C                   eval      ll = %len(string)
      *
      * see if one line command
     C                   if        ll - aa < 69
     C                   eval      %subst(xdata:9) =
     C                               %subst(string:aa:(ll - aa)+1)
     C                   eval      rrn1=rrn1+1
     C                   write     data1                                        LOAD SUBFILE
      *
      * multiline command
     C                   else
     C                   dou       aa>ll
     C                   eval      %subst(xdata:9) =  %subst(string:aa)
     C                   eval      rrn1=rrn1+1
     C                   write     data1                                        LOAD SUBFILE
     C                   clear                   xdata
     C                   add       69            aa
     C                   enddo
     C                   endif
     C                   clear                   xdata
     C                   eval      rrn1=rrn1+1
     C                   write     data1                                        LOAD SUBFILE
     C                   endsr
