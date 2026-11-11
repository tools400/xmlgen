# Rules of TOBi (The Object Builder for i) for XMLPREVIEW.
# Created by the migration of IFS Projects, completed from the STRPREPRC headers and
# the XMLGEN script QXMLGENS/XMLPREVIEW.

# TOBi reads %TEXT of the source only for rules without a custom recipe and passes the
# TEXT of a command on to its prerequisites, so TEXT is set for every custom recipe.
# TOBi does not resolve $(OBJLIB) in a private CMD_VLDCKR or CMD_PRDLIB, hence the custom
# recipe for XMLPREVIEW.

# --- Display file: CRTDSPF (RSTDSP(*NO) is the CL default, TOBi uses *YES) ---------------

XMLPREVIED.FILE: private RSTDSP := *NO
XMLPREVIED.FILE: xmlprevied.dspf

# --- Panel group ---------------------------------------------------------------------------

XMLPREVIEH.PNLGRP: private TEXT := help panel group for XMLPREVIEW command        jcr
XMLPREVIEH.PNLGRP: xmlprevieh.pnlgrp
	$(PNLGRPSRC_TO_PNLGRP_RECIPE)

# --- Programs ------------------------------------------------------------------------------

# CRTBNDRPG ... TRUNCNBR(*NO) DBGVIEW(*LIST) OPTION(*EVENTF); DFTACTGRP(*NO) is set in the
# H spec. TOBi does not pass TRUNCNBR to CRTBNDRPG, hence the custom recipe.
XMLPREVIER.PGM: private DBGVIEW := *LIST
XMLPREVIER.PGM: private TEXT := Preview uploads before install                 jcr
XMLPREVIER.PGM: xmlprevier.rpgle qxmlprev/copyright.rpgleinc XMLPREVIED.FILE
	$(eval XMLPREV_BNDRPGFLAGS = $(value CRTBNDRPGFLAGS))
	$(eval CRTBNDRPGFLAGS = $(value XMLPREV_BNDRPGFLAGS) TRUNCNBR(*NO))
	$(PGM.RPGLE_TO_PGM_RECIPE)
	$(eval CRTBNDRPGFLAGS = $(value XMLPREV_BNDRPGFLAGS))

# CRTBNDRPG ... DBGVIEW(*LIST)
XMLPREVINR.PGM: private DBGVIEW := *LIST
XMLPREVINR.PGM: xmlprevinr.rpgle

# CRTCLPGM ... OPTION(*LSTDBG)
XMLPREVIEC.PGM: private OPTION := *LSTDBG
XMLPREVIEC.PGM: private TEXT := Preview uploaded xml install members           jcr
XMLPREVIEC.PGM: xmlpreviec.clp
	$(CLP_TO_PGM_RECIPE)

XMLPREVIEV.PGM: private OPTION := *LSTDBG
XMLPREVIEV.PGM: private TEXT := Validity checker for XMLPREVIEW command        jcr
XMLPREVIEV.PGM: xmlpreviev.clp
	$(CLP_TO_PGM_RECIPE)

# --- Command -------------------------------------------------------------------------------

XMLPREVIEW.CMD: private TEXT := Preview uploaded xml member before install     jcr
XMLPREVIEW.CMD: private CMD_PGM := XMLPREVIEC
XMLPREVIEW.CMD: private CMD_HLPPNLGRP := $(OBJLIB)/XMLPREVIEH
XMLPREVIEW.CMD: private CMD_HLPID := XMLPREVIEW
XMLPREVIEW.CMD: private CMD_ALLOW := *BPGM *IPGM *EXEC *INTERACT *BATCH *BREXX *IREXX *BMOD *IMOD
XMLPREVIEW.CMD: xmlpreview.cmd XMLPREVIEC.PGM XMLPREVIEV.PGM XMLPREVIER.PGM XMLPREVINR.PGM XMLPREVIEH.PNLGRP
	$(eval CMD_VLDCKR := $(OBJLIB)/XMLPREVIEV)
	$(eval CMD_PRDLIB := $(OBJLIB))
	$(CMD_TO_CMD_RECIPE)
	$(eval CMD_VLDCKR := *NONE)
	$(eval CMD_PRDLIB := $(CURLIB))

# No rule for a_readme.txt (documentation).
