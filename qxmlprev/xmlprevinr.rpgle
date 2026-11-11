      *%METADATA                                                       *
      * %TEXT Extract embedded installer programs            jcr       *
      *%EMETADATA                                                      *
      *---------------------------------------------------------------------------------------
      * Extract embedded installer code from text.
      * Copyright (C) 2001    Craig Rutledge    <craig_rutledge@mohawkind.com>
      *
      * This program is free software, you can redistribute it and/or modify it
      * under the terms of the GNU General Public License as published by
      * the Free Software Foundation.  See GNU General Public License for details
      *---------------------------------------------------------------------------------------
     Fxmlinput  ip   f  112        disk                                         uploaded text
     Fxmlextracto    f  112        disk                                         parsed out
      *--------------------------------------------------------------------
     D srcSeqno        s              6s 2 inz(0)
     D write_flag      s              1n   inz(*off)
      *--------------------------------------------------------------------
     Ixmlinput  ns
     I                                 13   29  xmltag1
     I                                 18   35  xmltag2
     I                                 13  112  xmlcode
      *
      *--------------------------------------------------------------------
      * write records to temp installer source if flag is on
      *--------------------------------------------------------------------
     C                   select
     C                   when      write_flag = *on
     C                   if        xmltag2='</install_program>'
     C                   eval      *inlr=*on
     C                   return
     C                   endif
      *
     C                   eval      srcSeqno=srcSeqno+.01
     C                   except    write_one
      *
      *--------------------------------------------------------------------
      * Start of data to copy.  Create source files/mbrs as required.
      *--------------------------------------------------------------------
     C                   when      xmltag1='<install_program>'
     C                   eval      write_flag = *on
     C                   endsl
      *
     Oxmlextracte            write_one
     O                       srcSeqno             6
     O                                           12 '000000'
     O                       xmlcode            112
