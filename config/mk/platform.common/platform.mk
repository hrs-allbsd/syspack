#
# Sanity check
#
.for _V in DIFF SUDO TEST ENV 
. if !defined(${_V}_CMD) || empty(${_V}_CMD)
.  error ${_V}_CMD=${${_V}_CMD} is not found
. elif !exists(${_V}_CMD)
. endif
.endfor

.for _V in ID_U GETPERM_CMD GETOWNER_CMD
. if !defined(${_V})
.  error ${_V} is not defined
. endif
.endfor
