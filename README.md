# XMLGEN - A Tools/400 Utility

XMLGEN and XMLPREVIEW are utilities for distributing IBM i source members
as XML packages. They were initially developed by Craig Rutledge. I forked
them in order to add my own enhancements, which help me to create the
packages of my utilities.

* XMLGEN generates an XML package from a script member. The script lists
  the source members to include and the commands to execute at install time.
* XMLPREVIEW shows the content of an uploaded XML package and installs it.

## Changes

Both utilities contain changes and enhancements of the original code by
Thomas Raddatz.

XMLGEN:

* Command XMLGEN: parameters XMLMBR (name of the XML output member),
  ENCODING (encoding of the XML file) and AUTHOR (application author).
* Script command XMLGENCMD: parameters XCND (conditions), XRLS (execute
  depending on the release) and XDLTSPLF (delete the spooled file on success).
* Script command XMLGENMBR: parameters XPARAM (optional command parameter)
  and XCND (conditions).
* Script commands XMLGENSQL (execute SQL statements at install time),
  XMLGENCND (conditions), XMLGENSET (set variables), XMLGENOBJD (retrieve
  object description attributes) and XMLGENVRS (retrieve the version from the
  COPYRIGHT member).
* Conditions and release checks in the installer program.
* Service module XMLGENRS, shared by XMLGENR and XMLGENRV.

XMLPREVIEW:

* Parameter TGTRLS: the target release is shown and passed to the installer
  program, together with the conditions.

Both:

* Version and copyright information (COPYRIGHT members), STRPREPRC headers.
* 2026: Sources converted from source members to stream files, built with TOBi.

## Dependencies

Dependencies:

None.

The [TOBi](https://github.com/IBM/ibmi-tobi) package (The Object Builder for i,
`makei`) is required for building the utility.

## Installation

The sources are stream files, built with TOBi from the root of the cloned
repository. The objects are created in the library named by the environment
variable `XMLGEN_LIB`:

```clle
CRTLIB LIB(XMLGEN)
```

```sh
cd /path/to/xmlgen
export PATH=/QOpenSys/pkgs/bin:$PATH
XMLGEN_LIB=XMLGEN makei build
```

`makei build` stops with an error, if `XMLGEN_LIB` is not set. In RDi, set the
variable at the IFS project filter (Properties > IFS Project > Environment) of
the [IFS Projects](https://github.com/tools-400/ifs-projects) plug-in.

The modules XMLGENR, XMLGENRS and XMLGENRV stay in the library, because TOBi
needs them for rebuilding the programs.

## Usage

PDM options for launching the utilities:

XMLGEN:

```clle
XG - XMLGEN XMLSCRIPT(&N) SCRIPTSRCF(&L/QXMLGENS) SRCTOFILE(&L/QXML)
       AUTHOR('Thomas Raddatz')
```

XMLPREVIEW:

```clle
XP - XMLPREVIEW UPLOADMBR(&N) UPLOADSRCF(&L/QXML) TGTRLS(V6R1M0)
```

## Liability

This software is free and provided without warranty. You use it at your own risk: test it with non-critical data first, and back up your data before you use it. The [license](LICENSE) applies in addition.

---

2018, Thomas Raddatz
