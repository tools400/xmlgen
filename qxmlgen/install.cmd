      /*%METADATA                                                     */
      /* %TEXT Xml Package Installer                          jcr     */
      /*%EMETADATA                                                    */
/* ------------------------------------------------------------------------ */
/* INSTALL   - Used to install an Xml package.                              */
/* ------------------------------------------------------------------------ */
/* CRTCMD CMD(RADDATZ/INSTALL) PGM(*LIBL/INSTALLER)                         */
/*     SRCFILE(XMLGEN/QXMLGEN) SRCMBR(*CMD)                                 */
/* ------------------------------------------------------------------------ */
/* >>PRE-COMPILER<<                                                         */
/*   >>CRTCMD<< CRTCMD       CMD(&LI/&OB) +                                 */
/*                           SRCFILE(&SL/&SF) +                             */
/*                           SRCMBR(&SM);                                   */
/*   >>COMPILE<<                                                            */
/*     >>PARM<< PGM(*LIBL/INSTALLER);                                       */
/*   >>END-COMPILE<<                                                        */
/*   >>EXECUTE<<                                                            */
/* >>END-PRE-COMPILER<<                                                     */
/* ------------------------------------------------------------------------ */
             CMD        PROMPT('Xml Package Installer')

             PARM       KWD(SRCMBR ) TYPE(*CHAR) LEN( 10) MIN(1) +
                          PROMPT('Source member')

             PARM       KWD(SRCFILE) TYPE(*CHAR) LEN( 10) MIN(1) +
                          PROMPT('Source file')

             PARM       KWD(SRCLIB ) TYPE(*CHAR) LEN( 10) MIN(1) +
                          PROMPT('Source library')

             PARM       KWD(OVRSRCF) TYPE(*CHAR) LEN( 10) MIN(0) +
                          DFT(*NONE) +
                          SPCVAL((*NONE ' ')) +
                          PROMPT('Override target source file')

             PARM       KWD(DEFINE ) TYPE(*CHAR) LEN(128) MIN(0) +
                          PROMPT('Define conditions names')

             PARM       KWD(TGTRLS ) TYPE(*CHAR) LEN( 10) MIN(0) +
                          DFT(*CURRENT) +
                          PROMPT('Target release')

