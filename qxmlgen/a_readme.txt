XMLGEN and XMLPREVIEW are utilities initially developed by Craig Rutledge. I
forked these utilities in order to add my own enhancements helping me to create
packages of my utilities.

PDM options for launching the utilities:

XMLGEN:

   XG - XMLGEN XMLSCRIPT(&N) SCRIPTSRCF(&L/QXMLGENS) SRCTOFILE(&L/QXML)
          AUTHOR('Thomas Raddatz')

XMLPREVIEW:

   XP - XMLPREVIEW UPLOADMBR(&N) UPLOADSRCF(&L/QXML) TGTRLS(V6R1M0)

Compile members with:

   STRPREPRC USESRCFILE(&L/&F) USESRCMBR(&N) OPTION(*EVENTF) CHGOBJD(*NO)
     LIB(&O) OBJ(&N) SRCLIB(&L) SRCFILE(&F) SRCMBR(&N) USER0(&X)
     USER1(*LIST) USER2(*FULL)

2018, Thomas Raddatz
