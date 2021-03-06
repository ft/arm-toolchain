PACKAGES = gdb-binutils-arm-none-eabi-snapshot gcc-arm-none-eabi-snapshot
PACKAGES += newlib-snapshot libstdc++-arm-none-eabi-newlib-snapshot

SH = /bin/sh
BASH = /bin/bash
CP = /bin/cp
GENERATE_CHROOT = $(SH) ./tools/generate-chroot
GENERATE_HOOKS = $(BASH) ./tools/generate-hooks
GENERATE_ORIGINALS = $(SH) ./tools/generate-originals
GENERATE_SOURCE_PKGS = $(SH) ./tools/generate-source-pkgs
GENERATE_BINARY_PKGS = $(SH) ./tools/generate-binary-pkgs
FETCH_RESULTS = $(SH) ./tools/fetch-results
MAKE_CLEAN = $(SH) ./tools/make-clean
PBUILDER = $(BASH) ./tools/pbuilder
PBUILDER_RESULTS = ./cache/pbuilder/results
PB_UPDATE_FLAGS =

all: fetch-results

user:
	test -e user.txt || (id -u > user.txt && id -g >> user.txt)

chroot-hooks:
	$(GENERATE_HOOKS)

chroot: user chroot-hooks
	$(GENERATE_CHROOT)

chroot-update: chroot
	$(PBUILDER) update $(PB_UPDATE_FLAGS)

prepare:
	$(GENERATE_ORIGINALS) $(PACKAGES)

source-packages: prepare
	$(GENERATE_SOURCE_PKGS) $(PACKAGES)

binary-packages: source-packages chroot
	$(GENERATE_BINARY_PKGS) $(PBUILDER_RESULTS) $(PACKAGES)

clean:
	rm -f user.txt *~
	rm -Rf pbuilder-hooks
	@$(MAKE_CLEAN) $(PACKAGES)

cleaner: clean
	git submodule foreach --recursive git clean -xdf

pretty-clean: cleaner
	rm -f $(PBUILDER_RESULTS)/*.*

squeaky-clean:
	@printf 'WARNING!\n'
	@printf '    This target is really destructive!\n\n'
	@$(SH) ./tools/really
	$(MAKE) pretty-clean
	sudo rm -Rf cache
	git clean -xdf

fetch-results: binary-packages
	$(FETCH_RESULTS) $(PBUILDER_RESULTS) $(PACKAGES)

$(PACKAGES)::
	$(GENERATE_SOURCE_PKGS) $@
	$(GENERATE_BINARY_PKGS) $(PBUILDER_RESULTS) $@

.PHONY: all binary-packages fetch-results prepare source-packages
.PHONY: chroot chroot-hooks chroot-update
.PHONY: user clean cleaner pretty-clean squeaky-clean
