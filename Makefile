all: lib deps

lib:
	-which moonc && rm -fr lib && ( cd src ; moonc -t ../lib * )

#
# fulfil dependencies
#
DEPS  := $(shell cat deps)
deps: $(DEPS)
$(DEPS):
	mkdir -p modules
	echo Installing $@
	git clone http://github.com/$@ modules/$(@F)
	test -f modules/$(@F)/Makefile && make -C modules/$(@F)

.PHONY: all lib deps
.SILENT:
