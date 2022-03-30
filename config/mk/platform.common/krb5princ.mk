#
# krb5princ.mk: plugin for Kerberos 5 principal (krb5.keytab target)
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
.if !target(__<krb5princ.mk>__)
__<krb5princ.mk>__:
.endif

# TODO
# - Currently this plugin supports Heimdal only.
# - A single keytab only.

TARGETS.krb5princ=	${KRB5KEYTAB} \
			keygen
VARS.krb5princ=		KRB5KEYTAB \
			KRB5PRINC \
			KRB5PRINC_HOST \
			KRB5ADMINPRINC \
			KRB5REALM

KRB5PRINC?=	${KRB5PRINC_HOST}
KRB5KEYTAB?=	krb5.keytab
.if defined(KRB5REALM) && !empty(KRB5REALM)
KRB5PRINC_HOST?=host/${HOSTNAME}@${KRB5REALM}
.else
KRB5PRINC_HOST?=host/${HOSTNAME}
.endif
.if defined(KRB5ADMINPRINC) && !empty(KRB5ADMINPRINC)
KADMIN_CMD?=	kadmin -p ${KRB5ADMINPRINC} ext_keytab
.else
KADMIN_CMD?=	kadmin ext_keytab
.endif

krb5princ: ${KRB5KEYTAB}
.PHONY: krb5princ
${KRB5KEYTAB}:
	${KADMIN_CMD} -k ${.CURDIR}/${.TARGET} ${KRB5PRINC}

keygen:
.PHONY: keygen

.for P in ${KRB5PRINC}
TARGETS.krb5princ+=	keygen-${P}
keygen-${P}:
	${KADMIN_CMD} get ${P} || \
	${KADMIN_CMD} add \
	    --random-key \
	    --max-ticket-life=1d \
	    --max-renewable-life=1d \
	    --expiration-time=never \
	    --pw-expiration-time=never \
	    --attributes="" \
	    ${P}
keygen: keygen-${P}
.PHONY: keygen-${P}
.endfor
