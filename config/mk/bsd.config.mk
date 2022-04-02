#
# bsd.config.mk: A simple framework to organize config files.
#
# Copyright (c) 2000-2022 Hiroki Sato <hrs@allbsd.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

# XXX
.if !target(__<bsd.config.mk>__)
__<bsd.config.mk>__:

# .PARSEDIR is ".spx/syspack/config/mk"
CONFBASE:=	${.PARSEDIR}
MODULESBASE:=	${CONFBASE}/../modules
GLOBALBASE:=	${.PARSEDIR}/../../../..
#
# DEBUG messages
#
.if defined(DEBUG)
# XXX profiling
# _@_=d=$$(/bin/date "+>%H%m%S"); printf "%s " $$d;
_@_=
DEBUG_ECHO=	echo
.undef DEBUG
.else
_@_=	@
.endif
DEBUG_ECHO?=	true
SPX_ERROR=	${.newline}${.newline}${_FACE_REV}[SPX ERROR]:${_FACE_EXIT}
#
# Detect the current platform
#
UNAME_s!=	uname -s
UNAME_r!=	uname -r
.if empty(UNAME_s) || empty(UNAME_r)
.error ${SPX_ERROR} Platform detection failed (no uname(1) command)
.endif
_PLATFORM=	${UNAME_s:tl}
.if exists(${CONFBASE}/platform.${_PLATFORM}/platform.mk)
.include "${CONFBASE}/platform.${_PLATFORM}/platform.mk"
.else
.error ${SPX_ERROR} Unsupported platform: ${_PLATFORM}
.endif
.include "${CONFBASE}/platform.common/platform.mk"
#
CONF?=		/usr/local/etc/bsd.config.mk.conf
UID!=		${ID_U}
SETENV?=	${ENV_CMD} -i PATH="${PATH}" TERM="${TERM}"
#
# Headings for progress reporting
#
.if !defined(_COLS) || empty(_COLS)
_COLS=		80
.endif
_HEADING1=	heading() { \
		  printf "${_FACE_REV}%-*s${_FACE_EXIT}\n" ${_COLS} \
		     "==> $$*"; \
		}; heading
_HEADING1S=	heading() { \
		  printf "${_FACE_REV}%-*s${_FACE_EXIT}\n" ${_COLS} \
		     "    $$*"; \
		}; heading
#
# DESTDIR check
#
# XXX: DESTDIR can be modified in .mk files.  If it is defined as
# environment variable or a variable in the command-line options,
# it is impossible to change it.
#
.if defined(DESTDIR) && !empty(DESTDIR)
_D:=	${DESTDIR}
DESTDIR:=	${_D}x
.if "${_D}" == "${DESTDIR}"
.error DESTDIR must not be defined in a command-line option or environment variable.  Use INSTALL_DESTDIR instead
.else
DESTDIR:=	${_D}
.info DESTDIR=${_D}
.endif
.endif

# Ordering is important:
# 1: logging
# 2: per-group, per-file
# X: platform-specific
# Y: PLUGINS (user-defined)
# Z: check
_PLUGINS_1=	logging
_PLUGINS_2=	stored templates \
		install diff fetch status reconcile backup
_PLUGINS_X=	services jail krb5princ release pkg \
		world world-tarballs
_PLUGINS_Y=	${PLUGINS}
_PLUGINS_Z=	check
_PLUGINS=	${_PLUGINS_1} \
		${_PLUGINS_2} \
		${_PLUGINS_X} \
		${_PLUGINS_Y} \
		${_PLUGINS_Z}

VARS=		CONF \
		HOSTNAME \
		TARGETHOST \
		DESTDIR
TMPDIR?=	/tmp

#
# MODULES
#
.for _BASE in ${MODULESBASE} ${GLOBALBASE}/modules
_MODULE_PLUGINS_ALL!=\
	(cd ${_BASE} && /bin/ls -d */plugins*) 2>/dev/null || :
_MODULE_PLUGINS_ALL:=\
	${_MODULE_PLUGINS_ALL:C,\.[^.]+$,,}
.  for _M in ${MODULES}
.    if exists(${_BASE}/${_M}/plugins)
_MODULE_PLUGINS+=\
	${_MODULE_PLUGINS_ALL:M${_M}/plugins}
_MODULE_PLUGINSDIRS+=\
	${_BASE}/${_MODULE_PLUGINS_ALL:M${_M}/plugins}
.    endif
.  endfor

_MODULE_TEMPLATES_ALL!=\
	(cd ${_BASE} && /bin/ls -d */templates*) 2>/dev/null || :
_MODULE_TEMPLATES_ALL:=\
	${_MODULE_TEMPLATES_ALL:C,\.[^.]+$,,}
.  for _M in ${MODULES}
.    if exists(${_BASE}/${_M}/templates)
_MODULE_TEMPLATES+=\
	${_MODULE_TEMPLATES_ALL:M${_M}/templates}
_MODULE_TEMPLATESDIRS+=\
	${_BASE}/${_MODULE_TEMPLATES_ALL:M${_M}/templates}
.    endif
.  endfor

_MODULE_RECEIPES_ALL!=\
	(cd ${_BASE} && /bin/ls -d */receipes*) 2>/dev/null || :
_MODULE_RECEIPES_ALL:=\
	${_MODULE_RECEIPES_ALL:C,\.[^.]+$,,}
.  for _M in ${MODULES}
.    if exists(${_BASE}/${_M}/templates)
_MODULE_RECEIPES+=\
	${_MODULE_RECEIPES_ALL:M${_M}/receipes}
_MODULE_RECEIPESDIRS+=\
	${_BASE}/${_MODULE_RECEIPES_ALL:M${_M}/receipes}
.    endif
.  endfor
.endfor

# XXX
# Retrieve vars in ${INCVARS} from ${.CURDIR}/Makefile.inc and
# upper directories if any.
#
INCVARS= \
	TARGETHOST \
	JAIL
.for _V in ${INCVARS}
# .  if !defined(${_V}) || empty(${_V})
_${_V}!= \
	d=${.CURDIR} && \
	for i in 1 2 3 4 5 6 7 8 9; do \
	    if [ -r "$$d/Makefile.inc" ]; then \
		v=$$(${AWK_CMD} -F= '/${_V}[ 	]*=/ { print $$NF }' \
		  "$$d/Makefile.inc"); \
		case $$v in \
		"")	;; \
		*)	break ;; \
		esac; \
	    fi; \
	    d="$$d/.."; \
	done; \
	case $$i in \
	9) ;; \
	*) echo "$$d" "$$v" ;; \
	esac
_${_V}_DIR:=	${_${_V}:[@]:[1]:C/^[ 	]*//:C/[ 	]*$//}
_${_V}_VALUE:=	${_${_V}:[@]:[2]:C/^[ 	]*//:C/[ 	]*$//}
.    if !empty(_${_V})
${_V}_DIR:=${_${_V}_DIR}
${_V}:=${_${_V}_VALUE}
.    endif
# .  endif
.endfor

.if exists(${CONF})
.include "${CONF}"
.endif

# hostname check
.if !defined(HOSTNAME) || empty(HOSTNAME)
HOSTNAME!=	${HOSTNAME_CMD}
.endif
.if !make(package) && !defined(_MAKE_PACKAGE)
.  if !defined(TARGETHOST)
.    error ${SPX_ERROR} TARGETHOST is not defined
.  endif
.  if ${HOSTNAME} != ${TARGETHOST}
.    error ${SPX_ERROR} hostname mismatch: \
     here:${HOSTNAME} != target:${TARGETHOST}
.  endif
.endif

# Makeflie.inc check
_HAS_SUBDIR!=	${FIND_CMD} . -type d -a \! -name ".*"
.if !empty(_HAS_SUBDIR) && !exists(Makefile.inc)
all:
	@echo "Warning: create Makefile.inc by \"make Makefile.inc\" \
	  at this directory."
Makefile.inc:
	@echo ".include \"\$${.PARSEDIR}/../Makefile.inc\"" > ${.TARGET}
.endif

# XXX
# for package target (disabled due to its incompleteness)
_PKGBASEDIR=	${.OBJDIR}/.pkg
.if make(package)
DESTDIR:=	${_PKGBASEDIR}/${DESTDIR}
CLEANDIRS+=	${_PKGBASEDIR}
.endif

# Normalize //+ and trailing / in DESTDIR.
DESTDIR:=	${DESTDIR:C,//+,/,g:C,/$,,}

.if !exists(${SUDO_CMD})
.error ${SUDO_CMD}: not found.  config.mk depends on sudo(1).
.endif

# XXX:
#
#.for __target in ${SUBDIR_TARGETS}
#${__target}: _SUBDIR
#.endfor
#
# 2021/02/01 by hrs
#  solved in the newer make(1)?
#
# 2014/02/01 by hrs
#  _SUBDIR must be specified explicitly because
#  SUBDIR_TARGETS is evaluated only when bsd.subdir.mk is loaded.
#  bsd.prog.mk -> bsd.config.mk works but SUBDIR is ignored.
#  bsd.config.mk -> bsd.prog.mk works but FILESDIR_$file is not defined.
#

#
# FILESGROUPS must be defined before including bsd.config.mk.
#
.if !target(__<bsd.files.mk>__)
# XXX: must revisit
# .if !defined(FILESGROUPS) && !target(__<bsd.files.mk>__)

# FreeBSD-specific.  bsd.confs.mk is required for bsd.files.mk.
. if exists(${.MAKE.MAKEFILES:H:Msys.mk}/bsd.confs.mk)
.  include <bsd.confs.mk>
. endif

.include <bsd.files.mk>

# bmake-specific.  FreeBSD has functionlity of scripts.mk in bsd.prog.mk.
. if exists(${.MAKE.MAKEFILES:H:Msys.mk}/scripts.mk)
.  include <scripts.mk>
. endif 

# FreeBSD-specific.  bmake has functionality of links.mk in bsd.prog.mk.
# (bsd.opts.mk is FreeBSD-specific)
. if !empty(.MAKE.MAKEFILES:T:Mbsd.prog.mk) && \
     !empty(.MAKE.MAKEFILES:T:Mbsd.opts.mk)
.  include <bsd.links.mk>
. endif
.endif

.include <bsd.own.mk>	# for SHAREOWN and etc.

# XXX
# package target (disabled due to its incompleteness)
PMARKER="#----PACKAGE BEGIN"
# package: realinstall

package: pkg.tar.gz
.for F in before after
.if target(${F}install)
${DESTDIR}/${F}install.sh:
	${MAKE} -n -D_MAKE_PACKAGE ${F}install > ${.TARGET}
pkg.tar.gz: ${DESTDIR}/${F}install.sh
.endif
.endfor
pkg.tar.gz:
	# XXX staging (mtree?)
	mkdir -p ${DESTDIR}
	${MAKE} -D_MAKE_PACKAGE realinstall
	ls ${DESTDIR}
	cd ${DESTDIR} && tar czvf pkg.tar.gz .
#
# Load global plugins
#
. for P in ${_PLUGINS}
.  for O in common ${_PLATFORM}
.   for D in ${.PARSEDIR}/platform.${O} ${_MODULE_PLUGINSDIRS:S/$/.${O}/}
.    if exists(${D}/${P}.mk)
.     if defined(DEBUG)
.      info Loading ${D}/${P}.mk
.     endif
.     include "${D}/${P}.mk"
TARGETS+=	${TARGETS.${P}}
SUBDIR_TARGETS+=	${SUBDIR_TARGETS.${P}}
.     for V in ${VARS.${P}}
VARS+=		${V}.${P}
.     endfor
.     for D in ${DESC.${P}}
DESC+=		${D}.${P}
.     endfor
.    endif
.   endfor
.  endfor
. endfor

_DEFAULT_DIROWN?=	root
_DEFAULT_DIRMODE?=	0755

# FILESGROUPS loop
#  + Plugin stored
#
.for group in ${FILESGROUPS} STORED
. if defined(DEBUG)
.  info FILESGROUP loop: ${group}
. endif
#
# Define defalut perms if not defined
#
${group}OWN?=	${SHAREOWN}
${group}GRP?=	${SHAREGRP}
${group}MODE?=	${SHAREMODE}
${group}DIR_OWN?=	root
${group}DIR_GRP?=	wheel
${group}DIR_MODE?=	0755
#
# Define parameters for plugins:
# _dir, _dirown, and _dirmode
#
_group=	${group}
#
_dir=	${DESTDIR}${${group}DIR}
_dir:=	${_dir:C,[/]+,/,g}
.  if defined(${group}DIR_OWN)
_dirown=${${group}DIR_OWN}
.  else
_dirown=${_DEFAULT_DIROWN}
.  endif
.  if defined(${group}DIR_MODE)
_dirmode=${${group}DIR_MODE}
.  else
_dirmode=${_DEFAULT_DIRMODE}
.  endif
#
# Load group (FILESGROUPS) plugins
# _group: group name in FILESGROUPS
# _dir: pathname for the dir
# _dirown: owner for the dir
# _dirgrp: group for the dir
# _dirmode: mode for the dir
#
. if defined(${group}DIR)
.  if defined(DEBUG)
.   info FILESGROUP loop: ${group}DIR = ${${group}DIR}
.  endif
#
.  for P in ${_PLUGINS}
.   for O in common ${_PLATFORM}
.    for D in ${.PARSEDIR}/platform.${O} ${_MODULE_PLUGINSDIRS:S/$/.${O}/}
.     if exists(${D}/${P}.g.mk)
.      if defined(DEBUG)
.       info Loading ${D}/${P}.g.mk
.      endif
.      include "${D}/${P}.g.mk"
.     endif
.    endfor
.   endfor
.  endfor
. else
.  if defined(DEBUG)
.   info FILESGROUP loop: ${group}DIR = (not found)
.  endif
. endif

. if "${${group}:O:u:[#]}" != "${${group}:[#]}"
.  error ERROR: ${group} has a duplicate entry.
. endif
. for file in ${${group}}
#
# Define default perms if not defined
#
${group}OWN_${file}?=	${${group}OWN}
${group}GRP_${file}?=	${${group}GRP}
${group}MODE_${file}?=	${${group}MODE}
#
# Redefine _dir
#
.  if defined(${group}DIR_${file:T})
_dir=	${DESTDIR}${${group}DIR_${file:T}}
_dir:=	${_dir:C,[/]+,/,g}
.  endif
#
.  if defined(DEBUG)
.   info FILES loop: ${group}DIR_${file:T} = ${_dir}
.  endif
#
#
# Define parameters for plugins
#
.  if exists(${.OBJDIR}/${file})
_file=	${file}
.  else
_file=	${.CURDIR}/${file}
.  endif
_tag=	${_dir:S/:/_/g}-${file:T:S/:/_/g}
_fileown=	${${group}OWN_${file}}
_filegrp=	${${group}GRP_${file}}
_filemode=	${${group}MODE_${file}}
#
# Load file (FILES) plugins
# _tag: target label derived from the pathname
# _group: group name in FILESGROUPS
# _dir: pathname for the file
# _file: basename for the file
# _fileown: owner for the file
# _filegrp: group for the file
# _filemode: mode for the file
#
.  if defined(${group}DIR)
.   for O in common ${_PLATFORM}
.    for P in ${_PLUGINS}
.     for D in ${.PARSEDIR}/platform.${O} ${_MODULE_PLUGINSDIRS:S/$/.${O}/}
.      if exists(${D}/${P}.f.mk)
.       if defined(DEBUG)
.        info Loading ${D}/${P}.f.mk
.       endif
.       include "${D}/${P}.f.mk"
.      endif
.     endfor
.    endfor
.   endfor
.  endif

. endfor
.endfor
#
# Fixup DESTDIR
#
DESTDIR:=	${STAGEDIRPREFIX}${INSTALL_DESTDIR}/${DESTDIR}/${JAIL_DESTDIR}
DESTDIR:=	${DESTDIR:C,[/]+,/,g}
#
#
# Fixup INSTALL
#
#  When the current directory is not readable by root,
#  the install target invoked by root will fail.
#  If INSTALL_AS_ROOT is defined, the install target uses
#  sudo(1) for per-file installation to #  avoid this issue.
#
.if defined(INSTALL_AS_ROOT)
INSTALL:=	${SUDO_CMD} ${INSTALL}
.endif
#
# Helper vars
#
# CHECKYESNO
# $1: MSG
# _yes(): yes handler
#
.if !defined(BATCH)
CHECKYESNO=_ask() { \
		echo "$$1"; echo -n "OK? [y/N] "; read _ans; case $$_ans in \
		    [Yy]) _yes ;; \
		    *) echo "Abort."; \
		esac; \
	}; _ask
.else
CHECKYESNO=_yes
.endif
#
# Helper targets
#
root-check:
	@[ $$(${ID_U}) = 0 ] || \
	(echo ""; echo "=> [Error] Must be root."; echo ""; false)
#
# vars target
#
TARGETS+=	vars
vars.DESC=	show all parameters
vars +vars:
	@${_HEADING1} "[GLOBAL]"
.for V in ${VARS:N*\.*} _PLUGINS
. if ${V:M_PLUGINS}
	@${_HEADING1}  "[PLUGINS]:"
	@${_HEADING1S} " ${${V}}"
. else
.  if !defined(${V:R}) || empty(${V:R})
	@echo "  $V: (not defined)"
.  else
.   if ${V:R:M*DIR}
	@echo "  $V: ${${V:R}:tA}"
.   else
	@echo "  $V: ${${V:R}}"
.   endif
.  endif
. endif
.endfor
.for P in ${_PLUGINS}
. if !empty(DESC.${P})
	@echo ""; echo " <${P}> ${DESC.${P}}"
. endif
. for V in ${VARS:M*\.${P}:O:u}
.  if !defined(${V:R}) || empty(${V:R})
	@echo "   (${P}) ${V:R}: (not defined)"
.  else
.    if ${V:R:M*DIR}
	@echo "   (${P}) ${V:R}: ${${V:R}:tA}"
.    else
	@echo "   (${P}) ${V:R}: ${${V:R}}"
.    endif
.  endif
. endfor
.endfor
#
# modules target
#
TARGETS+=	modules
modules.DESC=	show all modules
modules +modules:
.if exists(${MODULESBASE})
	@/bin/ls ${MODULESBASE} 
.endif
.if exists(${GLOBALBASE}/modules)
	@/bin/ls ${GLOBALBASE}/modules
.endif
#
# Global targets for UI
#
# XXX: must be defined at the end because TARGETS is evaluated here
#
targets +targets:
.for T in ${TARGETS}
	@echo ' ${T}'
.endfor
	@${_HEADING1} "Use ${MAKE:T} targets-terse for more details"

targets-terse +targets-terse:
.for T in ${TARGETS}
	@echo ' ${T}:'
. if defined(${T}.DESC)
	@echo '	${${T}.DESC}'
. else
	@echo '	(no description)'
. endif
.endfor

#
# subdir.mk does not include bsd.obj.mk.
#
.include <bsd.obj.mk>

.endif	# include guard
