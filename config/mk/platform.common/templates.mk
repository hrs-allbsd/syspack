#
# templates.mk: Plugin for templates
#
# Copyright (c) 2000-2021 Hiroki Sato <hrs@allbsd.org>
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
.if !target(__<templates.mk>__)
__<templates.mk>__:
.endif
TEMPLATEBASE:=	${CONFBASE}/templates

TARGETS.templates=	templates
templates.DESC=		show templates
VARS.templates=	TEMPLATES \
		TEMPLATE_PLIST_DEFAULT \
		TEMPLATEDIR

.if !empty(_PLUGINS:Mjail)
TEMPLATE_PLIST_DEFAULT+= \
	JAIL_BASE=${JAIL_BASE} \
	JAIL=${JAIL}
.endif

TEMPLATEDIR+=	${TEMPLATEBASE} \
		${TEMPLATEBASE}/../../templates

_TEMPLATE_SUFFIX=	.in
_RESOLVED_TEMPLATE_SRCS:=

.for _TL in ${TEMPLATES:M*=*}
# destination=template|template|...::parameters
_DST_${_TL:hash}:=	${_TL:C/([^=]+)=(.*)/\1/}
_TS_${_TL:hash}:=	${_TL:C/([^=]+)=([^:]+).*/\2/}
_P_${_TL:hash}:=	${_TL:M*\:\:*:C/[^=]+=[^:]+::(.*)/\1/}
#
# Build a search path and define it as _TEMPLATEDIR
#
## 1st: Add .CURDIR
_TEMPLATEDIR:=	${.CURDIR}

## 2nd: add TEMPLATEDIR_template if defined
.  for _T in ${_TS_${_TL:hash}:S,|, ,g:[@]}
VARS.templates+=TEMPLATE_PLIST_${_T}
_TEMPLATEDIR+=	${TEMPLATEDIR_${_T}}
.  endfor

## 3rd: Add TEMPLATEDIR as global
VARS.templates+=TEMPLATE_PLIST_FILE_${_DST_${_TL:hash}}
_TEMPLATEDIR+=	${TEMPLATEDIR}

## 4th: Add _MODULE_TEMPLATESDIRS
_TEMPLATEDIR+=	${_MODULE_TEMPLATESDIRS}
#
#
# Build _TEMPLATE_PLIST
#
## 1st: Add _TEMPLATE_PLIST_DEFAULT
_TEMPLATE_PLIST_${_TL:hash}:= ${TEMPLATE_PLIST_DEFAULT}
#
## 2nd: Add _TEMPLATE_PLIST_template if defined
.  for _T in ${_TS_${_TL:hash}:S,|, ,g:[@]}
_TEMPLATE_PLIST_${_TL:hash}+= ${TEMPLATE_PLIST_${_T}}
.  endfor
#
## 3rd: Add TEMPLATE_PLIST_FILE_destination
_TEMPLATE_PLIST_${_TL:hash}+= \
    ${TEMPLATE_PLIST_FILE_${_DST_${_TL:hash}}} \
#
## 4th: Add _PLIST
_PLIST:=${_P_${_TL:hash}:S/,/ /g:[@]}
_TEMPLATE_PLIST_${_TL:hash}+= \
    ${_PLIST}
#
# Uniqify the key-value pairs in _TEMPLATE_PLIST
.  for R in ${_TEMPLATE_PLIST_${_TL:hash}:M*=*:C/([^=]+)=.*/\1/:O:u}
#   Extract the last component
.    for _L in ${_TEMPLATE_PLIST_${_TL:hash}:M*=*:M${R}=*}
_LC:= 	${_L}
.    endfor # Last component extraction
# Use := instead of += in order to expand _LC
_REINPLACE_ARGS_${_TL:hash}:= \
	${_REINPLACE_ARGS_${_TL:hash}} \
	-e 's|%%${_LC:C/([^=]+)=.*/\1/:Q}%%|${_LC:C/[^=]+=(.*)/\1/:Q}|'
.  endfor # Key-value pair
#
# Build _TEMPLATE_KFLIST
#
_KFLIST:=${_TEMPLATE_PLIST_${_TL:hash}:N*=*:N\+*}
#
# Lookup _KFLIST in ${_TEMPLATEDIR}
#
_TEMPLATE_KFLIST_${_TL:hash}:=
.for _F in ${_KFLIST}
_KFLIST_${_F:hash}=
. for _D in ${_TEMPLATEDIR}
.  if exists(${_D}/${_F})
_KFLIST_${_F:hash}+=	${_D}/${_F}
.  endif
. endfor
. if empty(_KFLIST_${_F:hash})
.  error ${SPX_ERROR} \
         Template parameter file "${_F}" is not found.\
         The template search path was ${_TEMPLATEDIR:tA}
. endif
# Use the first item
_TEMPLATE_KFLIST_${_TL:hash}+=	${_KFLIST_${_F:hash}:[1]}
.endfor
#
# Construct _REINPLACE_ARGS.  Params in the line, then ones in files.
#
.for _F in ${_TEMPLATE_KFLIST_${_TL:hash}}
_REINPLACE_ARGS_KF_${_F:hash}!=	sed 's,^,s|%%,;s,=,%%|,;s,$$,|;,' < ${_F}
_REINPLACE_ARGS_${_TL:hash}:= \
	${_REINPLACE_ARGS_${_TL:hash}} \
	-e '${_REINPLACE_ARGS_KF_${_F:hash}}'
.endfor
#
# Build _TEMPLATE_FLIST
#
_FLIST:=${_TEMPLATE_PLIST_${_TL:hash}:M\+*}
#
# Lookup ${_TEMPLATEDIR}
#
_TEMPLATE_FLIST_${_TL:hash}:=
.for _F in ${_FLIST}
_FLIST_${_F:hash}=
. for _D in ${_TEMPLATEDIR}
.  if exists(${_D}/${_F})
_FLIST_${_F:hash}+=	${_D}/${_F}
.  endif
. endfor
. if empty(_FLIST_${_F:hash})
.  error ${SPX_ERROR} \
         Template filter file "${_F}" is not found.\
         The template search path was ${_TEMPLATEDIR:tA}
. endif
# Use the first item
_TEMPLATE_FLIST_${_TL:hash}+=	${_FLIST_${_F:hash}:[1]}
.endfor
.if empty(_TEMPLATE_FLIST_${_TL:hash})
_TEMPLATE_FLIST_${_TL:hash}=	${CAT_CMD}
.endif
#
# Look up _SRCS (templates) from _TEMPLATEDIR
#
_SRCS:=${_TS_${_TL:hash}:S,|, ,g:[@]:S,$,${_TEMPLATE_SUFFIX},}
#
# XXX: Do not use _DST in the shell commands because expansion of
#      _DST occurs upon evaluation.
#
.  if !target(${_DST_${TL:hash}})
.    for _S in ${_SRCS}
.      for _D in ${_TEMPLATEDIR}
.        if exists(${_D}/${_S})
_SLIST_${_TL:hash}_${_S:hash}+=${_D}/${_S}
.        endif
.      endfor
# Use the first item
_SRCS_${_TL:hash}+=	${_SLIST_${_TL:hash}_${_S:hash}:[1]}
.      if empty(_SRCS_${_TL:hash})
.        error ${SPX_ERROR} \
               Template file "${_S}" is not found.\
               The template search path was ${_TEMPLATEDIR:tA}
.      endif
_RESOLVED_TEMPLATE_SRCS:=${_RESOLVED_TEMPLATE_SRCS} ${_SRCS_${_TL:hash}}
.    endfor
#
# Primary target
#
DEPENDS_${_TL:hash}=	${_SRCS_${_TL:hash}} \
			${_TEMPLATE_KFLIST_${_TL:hash}} \
			${_TEMPLATE_FLIST_${_TL:hash}}
${_DST_${_TL:hash}}: ${DEPENDS_${_TL:hash}}
	@${_HEADING1} \
	    "Create ${.TARGET:T} (template: ${_TS_${_TL:hash}:S,|, + ,g})"
.    for _F in ${_TEMPLATE_FLIST}	# Sanity checking of the filters
	${_@_}\
	    perm=$$(${GETPERM_CMD} ${_F}); \
	    case $$perm in \
	    [0-9][0-9][0-9][75]) : ;; \
	    *) echo "${SPX_ERROR}" \
	        "filter ${_F:tA} is not executable (mode is $$perm)."; \
	        false ;; \
	    esac
.    endfor
	${_@_}\
	${CAT_CMD} ${_SRCS_${_TL:hash}} | \
	    ${SED_CMD} ${_REINPLACE_ARGS_${_TL:hash}} \
	    | ${_TEMPLATE_FLIST_${_TL:hash}:ts|} \
	    > ${.TARGET} || (rm -f ${.TARGET})
CLEANFILES+=	${_DST_${_TL:hash}}
.  endif
.endfor # Each template

templates:
	@${_HEADING1} "Template search path:"
	@for D in ${_TEMPLATEDIR:tA}; do \
	    echo "  $$D"; \
	done
	@${_HEADING1} "Used Templates:"
	@for F in ${_RESOLVED_TEMPLATE_SRCS:tA:O:u}; do \
	    echo "  $${F%${_TEMPLATE_SUFFIX}}"; \
	done
	@echo
	@${_HEADING1} "Available Templates:"
.for _D in ${_TEMPLATEDIR:N${.CURDIR}}
	@cd ${_D} && /bin/ls | \
	    ${SED_CMD} -e "/+.*/d;s/${_TEMPLATE_SUFFIX:q}$$//;s|^|  ${_D:tA:Q}/|" 
.endfor
	@${_HEADING1} "Available Filters:"
.for _D in ${_TEMPLATEDIR:N${.CURDIR}}
	@cd ${_D} && /bin/ls +* 2>/dev/null | \
	    ${SED_CMD} -e "s/${_TEMPLATE_SUFFIX:q}$$//;s|^|  ${_D:tA:Q}/|" 
.endfor

.PHONY: tempmates
