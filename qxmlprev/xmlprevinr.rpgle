**free
      //%METADATA                                                      *
      // %TEXT Extract embedded installer programs            jcr      *
      //%EMETADATA                                                     *
//---------------------------------------------------------------------------------------
// Extract embedded installer code from text.
// Copyright (C) 2001    Craig Rutledge    <craig_rutledge@mohawkind.com>
//
// This program is free software, you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation.  See GNU General Public License for details
//---------------------------------------------------------------------------------------
dcl-f xmlinput disk(112);  // uploaded text
dcl-f xmlextract disk(112) usage(*output);  // parsed out
//--------------------------------------------------------------------
dcl-s srcSeqno zoned(6:2) inz(0);
dcl-s write_flag ind inz(*off);
//--------------------------------------------------------------------
dcl-ds xmlRecord len(112);  // record of xmlinput
  xmltag1 char(17) pos(13);
  xmltag2 char(18) pos(18);
  xmlcode char(100) pos(13);
end-ds;
dcl-ds srcRecord len(112) qualified;  // record of xmlextract
  srcSeq zoned(6:2) pos(1);
  srcDat char(6) pos(7);
  srcDta char(100) pos(13);
end-ds;

//--------------------------------------------------------------------
// read the uploaded text (formerly the primary file of the RPG cycle)
//--------------------------------------------------------------------
read xmlinput xmlRecord;
dow not %eof(xmlinput);

  //--------------------------------------------------------------------
  // write records to temp installer source if flag is on
  //--------------------------------------------------------------------
  select;
  when write_flag = *on;
    if xmltag2='</install_program>';
      *inlr=*on;
      return;
    endif;

    srcSeqno=srcSeqno+.01;
    srcRecord.srcSeq = srcSeqno;
    srcRecord.srcDat = '000000';
    srcRecord.srcDta = xmlcode;
    write xmlextract srcRecord;

  //--------------------------------------------------------------------
  // Start of data to copy.  Create source files/mbrs as required.
  //--------------------------------------------------------------------
  when xmltag1='<install_program>';
    write_flag = *on;
  endsl;

  read xmlinput xmlRecord;
enddo;

*inlr=*on;
