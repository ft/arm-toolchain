PACKAGES = gcc-arm-none-eabi-snapshot gdb-binutils-arm-none-eabi-snapshot

SH = /bin/sh
CP = /bin/cp
GENERATE_CHROOT = $(SH) ./tools/generate-chroot
GENERATE_ORIGINALS = $(SH) ./tools/generate-originals
GENERATE_SOURCE_PKGS = $(SH) ./tools/generate-source-pkgs
GENERATE_BINARY_PKGS = $(SH) ./tools/generate-binary-pkgs
FETCH_RESULTS = $(SH) ./tools/fetch-results
MAKE_CLEAN = $(SH) ./tools/make-clean
PBUILDER = $(SH) ./tools/pbuilder
PBUILDER_RESULTS = ./cache/pbuilder/results

all: fetch-results

user:
	test -e user.txt || (id -u > user.txt && id -g >> user.txt)

chroot: user
	$(GENERATE_CHROOT)

prepare:
	$(GENERATE_ORIGINALS) $(PACKAGES)

source-packages: prepare
	$(GENERATE_SOURCE_PKGS) $(PACKAGES)

binary-packages: source-packages chroot
	$(GENERATE_BINARY_PKGS) $(PBUILDER_RESULTS) $(PACKAGES)

clean:
	rm -f user.txt *~
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
	$(GENERATE_BINARY_PKGS) $@

.PHONY: all binary-packages chroot fetch-results prepare source-packages
.PHONY: user clean cleaner pretty-clean squeaky-clean
