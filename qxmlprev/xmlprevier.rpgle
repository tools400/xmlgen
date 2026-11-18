**free
//%METADATA                                                      *
// %TEXT Preview uploads before install                 jcr      *
//%EMETADATA                                                     *
ctl-opt dftactgrp(*no) actgrp(*caller);
//---------------------------------------------------------------------------------------
// Preview XML upload before install.
// Copyright (C) 2001    Craig Rutledge    <craig_rutledge@mohawkind.com>
//
// This is a 'for your protection' program.  It is very strongly recommended you run
// this program over any uploaded XMLGEN generated source before you commit to install.
//
// This subfile program will list the
// 1. source members about to installed.
// 2. source files that may be created.
// 3. any commands that will be executed during installation.
//
// It is your responsibility to verify these operations performed during the
// install are not inimical to your environment.
//
// If you are satisfied with the upload, press F10 to auto install.
//
//-----
// This program is free software, you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation.  See GNU General Public License for details
//---------------------------------------------------------------------------------------------
// >>PRE-COMPILER<<
//   >>CRTCMD<< CRTBNDRPG    PGM(&LI/&OB) +
//                           SRCFILE(&SL/&SF) SRCMBR(&SM);
//   >>COMPILE<<
//     >>PARM<< TRUNCNBR(*NO);
//     >>PARM<< DBGVIEW(*LIST);
//     >>PARM<< OPTION(*EVENTF);
//   >>END-COMPILE<<
//   >>EXECUTE<<
// >>END-PRE-COMPILER<<
//---------------------------------------------------------------------------------------
/copy 'qxmlprev/copyright.rpgleinc'

dcl-f xmlinput disk(112);
dcl-f xmlprevied workstn sfile(data1: rrn1);
dcl-s String varchar(500);
dcl-s aa uns(5) inz(0);
dcl-s ll uns(5) inz(0);
dcl-s cc uns(5) inz(0);
dcl-s rrn1 uns(5);
dcl-s SequenceNum packed(3: 0);
//--------------------------------------------------------------------
dcl-pr main extpgm('XMLPREVIER'); // Input Parms
  i_smbr    char(10) const;
  i_sfil    char(10) const;
  i_slib    char(10) const;
  i_usrsfil char(10) const;
  i_tgtrls  char(10) const;
  i_action  char(4);
end-pr;
//    -------------------------------------------------------------
dcl-pi main; // Input Parms
  i_smbr    char(10) const;
  i_sfil    char(10) const;
  i_slib    char(10) const;
  i_usrsfil char(10) const;
  i_tgtrls  char(10) const;
  i_action  char(4);
end-pi;
//--------------------------------------------------------------------
dcl-ds xmlRecord len(112); // record of xmlinput
  xmltag1       char(9) pos(13);
  xmlinstallpgm char(17) pos(13);
  xmltag2       char(10) pos(18);
  xmlcode       char(100) pos(13);
end-ds;
//--------------------------------------------------------------------
i_action='N';  // F10 ='Y'

read xmlinput xmlRecord;
dow (not %eof);

  select;
  // determine if install_program source is included in text
  when (xmlinstallpgm ='<install_program>');
    *in40=*on;  // enable install

  // Extract values based on xml tags and load to subfile record(s)
  when (xmltag1 = 'mbrname =');
    SequenceNum = SequenceNum + 1;
    xdata=%trimr(%editc(SequenceNum:'4'));
    %subst(xdata:5:3)='mbr';
    %subst(xdata:9:10) =
              %subst(xmlcode:13:10);

  when (xmltag1 = 'mbrtype =');
    %subst(xdata:20:10) =
             %subst(xmlcode:13:10);

  when (xmltag1 = 'mbrtext =');
    %subst(xdata:43) =
             %subst(xmlcode:13:50);

  when (xmltag1 = 'srcfile =');
    if (i_usrsfil='*DEFAULTS ');  // xmlpreview ove
      %subst(xdata:31:10) = %subst(xmlcode:13:10);
    else;
      %subst(xdata:31:10) = i_usrsfil;
    endif;

  when (xmltag1 = 'srccssid=');
    rrn1=rrn1+1;
    write data1;  // LOAD SUBFILE

  //--------------------------------------------------------------------
  // qcmdexc statement. Build statement from each record between start
  // and stop tags.  When stop tag is found, process into subfile records
  //--------------------------------------------------------------------
  when (xmltag1 = '<qcmdexc>');
    clear string;
    aa=1;
    read xmlinput xmlRecord;
    dow (xmltag2<>'</qcmdexc>');
      %len(string)=%len(string)+100;
      %subst(string:aa:100)=xmlcode;
      aa=aa+100;
      read xmlinput xmlRecord;
    enddo;
    exsr TolibToken;
    exsr srParseCmd;
  endsl;

  read xmlinput xmlRecord;
enddo;

//----------------------------------------------------------------
// Show subfile.  F3/F12 = Exit   F10=Run Install
//----------------------------------------------------------------
*in01 = (rrn1>0);  // THERE ARE RECO
*in02 = *on;  // DISPLAY CONTRL
dow (*inkc = *off);
  write keys;  // GET USER RESPO
  exfmt contrl1;  // VIEW 1
  select;
  when (*inkc or *inkl);  // f3 or f12
    leave;
  when (*inkj  and *in40);  // F10=install
    i_action='Y';  // CALL INSTALL
    leave;
  endsl;
enddo;
*inlr=*on;
return;

//--------------------------------------------------------------------
// Replace &tolib (no matter how many times it is in the string)
// with whatever library the user has selected at run time.
//  Must replace create-from source files if user has selected override.
//--------------------------------------------------------------------
begsr TolibToken;
  aa=%scan('&tolib':string);
  dow (aa>0);
    string=%replace(%trimr(i_slib):string:
      aa:6);
    aa=%scan('&tolib':string);
  enddo;

  if (i_usrsfil<>'*DEFAULTS ');
    aa=%scan('SRCFILE(':string);
    if (aa>0);
      aa=%scan('/':string:aa);
      if (aa>0);
        ll=%scan(')':string:aa);
        string=%replace(%trimr(i_usrsfil):string:
          aa+1:ll-(aa+1));
      endif;
    endif;
  endif;

endsr;

//---------------------------------------------------------------------------------------
// write commands to subfile.
//---------------------------------------------------------------------------------------
begsr srParseCmd;
  clear xdata;
  rrn1=rrn1+1;
  write data1;  // LOAD SUBFILE
  SequenceNum = SequenceNum + 1;
  xdata=%trimr(%editc(SequenceNum:'4'));
  %subst(xdata:5:3)='cmd';

  aa=1;
  ll = %len(string);

  // see if one line command
  if (ll - aa < 69);
    %subst(xdata:9) =
      %subst(string:aa:(ll - aa)+1);
    rrn1=rrn1+1;
    write data1;  // LOAD SUBFILE

  // multiline command
  else;
    dou (aa>ll);
      %subst(xdata:9) =  %subst(string:aa);
      rrn1=rrn1+1;
      write data1;  // LOAD SUBFILE
      clear xdata;
      aa = aa + 69;
    enddo;
  endif;
  clear xdata;
  rrn1=rrn1+1;
  write data1;  // LOAD SUBFILE
endsr;
