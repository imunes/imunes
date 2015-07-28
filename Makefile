USEGNU=gmake --no-print-directory $*
info:
	@$(USEGNU)
.DEFAULT:
	@$(USEGNU)
