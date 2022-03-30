.if !defined(HOSTNAME) || empty(HOSTNAME)
HOSTNAME!=	${HOSTNAME_CMD}
.endif

.include "${.PARSEDIR}/mk/bsd.config.mk"
