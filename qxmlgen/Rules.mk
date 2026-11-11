# Rules of TOBi (The Object Builder for i) for XMLGEN.
# Created by the migration of IFS Projects, completed from the STRPREPRC headers and
# the XMLGEN script QXMLGENS/XMLGEN.
# TGTRLS(V6R1M0) of the headers of XMLGENR and XMLGENRS is not taken over: V7R5 cannot
# create objects for V6R1.

# --- Modules: CRTRPGMOD ... TRUNCNBR(*NO) DBGVIEW(*LIST) OPTION(*EVENTF) ---------------
# TOBi does not pass TRUNCNBR to CRTRPGMOD, hence the custom recipes.
# TOBi reads %TEXT of the source only for rules without a custom recipe and passes the
# TEXT of a command on to its prerequisites, so TEXT is set for every custom recipe.

%.MODULE: private DBGVIEW := *LIST

XMLGENR.MODULE: private TEXT := gen xml source file
XMLGENR.MODULE: xmlgenr.rpgle qxmlgen/copyright.rpgleinc qxmlgen/xmlgenrs_h.rpgleinc
	$(eval XMLGEN_RPGMODFLAGS = $(value CRTRPGMODFLAGS))
	$(eval CRTRPGMODFLAGS = $(value XMLGEN_RPGMODFLAGS) TRUNCNBR(*NO))
	$(RPGLE_TO_MODULE_RECIPE)
	$(eval CRTRPGMODFLAGS = $(value XMLGEN_RPGMODFLAGS))

XMLGENRS.MODULE: private TEXT := XMLGENRV + XMLGENR service module
XMLGENRS.MODULE: xmlgenrs.rpgle qxmlgen/copyright.rpgleinc qxmlgen/regex.rpgleinc qxmlgen/xmlgenrs_h.rpgleinc
	$(eval XMLGEN_RPGMODFLAGS = $(value CRTRPGMODFLAGS))
	$(eval CRTRPGMODFLAGS = $(value XMLGEN_RPGMODFLAGS) TRUNCNBR(*NO))
	$(RPGLE_TO_MODULE_RECIPE)
	$(eval CRTRPGMODFLAGS = $(value XMLGEN_RPGMODFLAGS))

XMLGENRV.MODULE: private TEXT := validate selected script and members           jcr
XMLGENRV.MODULE: xmlgenrv.rpgle qxmlgen/copyright.rpgleinc qxmlgen/xmlgenrs_h.rpgleinc
	$(eval XMLGEN_RPGMODFLAGS = $(value CRTRPGMODFLAGS))
	$(eval CRTRPGMODFLAGS = $(value XMLGEN_RPGMODFLAGS) TRUNCNBR(*NO))
	$(RPGLE_TO_MODULE_RECIPE)
	$(eval CRTRPGMODFLAGS = $(value XMLGEN_RPGMODFLAGS))

# --- Programs: CRTPGM ... ACTGRP(*NEW) DETAIL(*BASIC) TEXT(*ENTMODTXT) -------------------

XMLGENR.PGM: private ACTGRP := *NEW
XMLGENR.PGM: private DETAIL := *BASIC
XMLGENR.PGM: private ALWRINZ := *NO
XMLGENR.PGM: private TEXT := gen xml source file
XMLGENR.PGM: XMLGENR.MODULE XMLGENRS.MODULE

XMLGENRV.PGM: private ACTGRP := *NEW
XMLGENRV.PGM: private DETAIL := *BASIC
XMLGENRV.PGM: private ALWRINZ := *NO
XMLGENRV.PGM: private TEXT := validate selected script and members           jcr
XMLGENRV.PGM: XMLGENRV.MODULE XMLGENRS.MODULE

# CRTBNDRPG ... DBGVIEW(*LIST) OPTION(*EVENTF); DFTACTGRP(*NO) is set in the H spec.
INSTALLER.PGM: private DBGVIEW := *LIST
INSTALLER.PGM: installer.rpgle

# CRTCLPGM ... OPTION(*LSTDBG)
XMLGENC.PGM: private OPTION := *LSTDBG
XMLGENC.PGM: private TEXT := Generate xml members for download              jcr
XMLGENC.PGM: xmlgenc.clp
	$(CLP_TO_PGM_RECIPE)

# --- Panel group -------------------------------------------------------------------------

XMLGENP.PNLGRP: private TEXT := Help panel group for XMLGEN command            jcr
XMLGENP.PNLGRP: xmlgenp.pnlgrp
	$(PNLGRPSRC_TO_PNLGRP_RECIPE)

# --- Commands ------------------------------------------------------------------------------
# TOBi takes PGM, HLPPNLGRP and HLPID from the command name, unless they are set here.
# Programs and panel groups are qualified with the target library, so that an older
# installation in the library list is not used. TOBi does not resolve $(OBJLIB) in a
# private CMD_VLDCKR or CMD_PRDLIB, hence the custom recipe for XMLGEN.

XMLGEN.CMD: private TEXT := Generate xml source member for download        jcr
XMLGEN.CMD: private CMD_PGM := XMLGENC
XMLGEN.CMD: private CMD_HLPPNLGRP := $(OBJLIB)/XMLGENP
XMLGEN.CMD: private CMD_HLPID := XMLGEN
XMLGEN.CMD: private CMD_ALLOW := *BPGM *IPGM *EXEC *INTERACT *BATCH *BREXX *IREXX *BMOD *IMOD
XMLGEN.CMD: xmlgen.cmd XMLGENC.PGM XMLGENRV.PGM XMLGENR.PGM XMLGENP.PNLGRP
	$(eval CMD_VLDCKR := $(OBJLIB)/XMLGENRV)
	$(eval CMD_PRDLIB := $(OBJLIB))
	$(CMD_TO_CMD_RECIPE)
	$(eval CMD_VLDCKR := *NONE)
	$(eval CMD_PRDLIB := $(CURLIB))

INSTALL.CMD: private CMD_PGM := INSTALLER
INSTALL.CMD: private CMD_HLPPNLGRP := *NONE
INSTALL.CMD: private CMD_HLPID := *NONE
INSTALL.CMD: install.cmd INSTALLER.PGM

# Commands of the script members: used for prompting only, their programs do not exist.

XMLGENCMD.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENCMD.CMD: private CMD_HLPID := *NONE
XMLGENCMD.CMD: xmlgencmd.cmd

XMLGENCND.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENCND.CMD: private CMD_HLPID := *NONE
XMLGENCND.CMD: xmlgencnd.cmd

XMLGENINC.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENINC.CMD: private CMD_HLPID := *NONE
XMLGENINC.CMD: xmlgeninc.cmd

XMLGENMBR.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENMBR.CMD: private CMD_HLPID := *NONE
XMLGENMBR.CMD: xmlgenmbr.cmd

XMLGENOBJD.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENOBJD.CMD: private CMD_HLPID := *NONE
XMLGENOBJD.CMD: private CMD_ALLOW := *IPGM *BPGM
XMLGENOBJD.CMD: xmlgenobjd.cmd

XMLGENSET.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENSET.CMD: private CMD_HLPID := *NONE
XMLGENSET.CMD: xmlgenset.cmd

XMLGENSQL.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENSQL.CMD: private CMD_HLPID := *NONE
XMLGENSQL.CMD: xmlgensql.cmd

XMLGENVRS.CMD: private CMD_HLPPNLGRP := *NONE
XMLGENVRS.CMD: private CMD_HLPID := *NONE
XMLGENVRS.CMD: private CMD_ALLOW := *BPGM *IPGM *BREXX *IREXX *BMOD *IMOD
XMLGENVRS.CMD: xmlgenvrs.cmd

# No rule for a_readme.txt (documentation).
