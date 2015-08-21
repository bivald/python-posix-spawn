# Copyright (c) 2015 Metaswitch Networks

# Recursive wildcard function.
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# Maintainer name, embedded itn he metadata.
MAINTAINER := Shaun Crampton <shaun@projectcalico.org>

# Default PPA to upload to.
PPA := ppa:fasaxc/tests

# Pull the version directly from setup.py.
VERSION := $(shell python ./setup.py --version)

# This version should be incremented for each repaging of the same Python
# package version.  However, this doesn't work too well because the Python
# source package build isn't repeatable and Launchpad complains if the source
# package changes.  For now, it's easier to just bump the post versions in the
# python package for each rebuild.
DEBIAN_VERSION := 1

# This is the full version, as used i the filename of the dsc and debs.
FULL_VERSION := $(VERSION)-$(DEBIAN_VERSION)

# Find all the files that affect the build.
PYTHON_FILES := $(call rwildcard,posix_spawn/,*.py) $(wildcard *.py)
CDEF_FILES := $(wildcard posix_spawn/c/*.[ch])
DEB_FILES := debian/*
SOURCE_FILES := $(PYTHON_FILES) $(CDEF_FILES) LICENSE MANIFEST.in README.md
CHANGES_FILENAME := posix-spawn_$(FULL_VERSION)_source.changes
SOURCE_DEB_OUTPUT := deb_dist/posix-spawn_$(FULL_VERSION).dsc \
                     deb_dist/$(CHANGES_FILENAME) \
                     deb_dist/posix-spawn_$(VERSION).orig.tar.gz \
                     deb_dist/posix-spawn_$(FULL_VERSION).debian.tar.gz

.PHONY: all
all: test signed-src-deb

# Source tarfile.
dist/posix-spawn-$(VERSION).tar.gz: $(SOURCE_FILES)
	python setup.py sdist

# Binary tarfile.
dist/posix-spawn-$(VERSION).linux-x86_64.tar.gz: $(SOURCE_FILES)
	python setup.py bdist

.PHONY: sdist
sdist: dist/posix-spawn-$(VERSION).tar.gz

.PHONY: bdist
bdist: dist/posix-spawn-$(VERSION).linux-x86_64.tar.gz

# Build a debian source distribution.
.PHONY: src-deb
src-deb: $(SOURCE_DEB_OUTPUT)
$(SOURCE_DEB_OUTPUT): $(SOURCE_FILES) $(DEB_FILES)
	./check_env.sh
	python setup.py --command-packages=stdeb.command sdist_dsc \
	    --debian-version $(DEBIAN_VERSION)

# Lint the source deb.
.PHONY: lint
lint: src-deb
	cd deb_dist; lintian -i $(CHANGES_FILENAME)

# Build the signed source deb, ready for upload.  Requires the DEBSIGN_KEYID
# environment variable to be set to the ID of the key to use for signing.
.PHONY: signed-src-deb
signed-src-deb: deb_dist/signed
deb_dist/signed: $(SOURCE_DEB_OUTPUT)
ifndef DEBSIGN_KEYID
	$(error DEBSIGN_KEYID is undefined)
	exit 1
endif
	cd deb_dist; debsign -k $(DEBSIGN_KEYID) *.changes && touch signed

# Shortcut to build a binary deb package for the current system.
.PHONY: deb
deb: deb_dist/python-posix-spawn_$(FULL_VERSION)_amd64.deb
deb_dist/python-posix-spawn_$(FULL_VERSION)_amd64.deb: $(SOURCE_FILES) $(DEB_FILES)
	./check_env.sh
	python setup.py --command-packages=stdeb.command bdist_deb

# Upload the signed source package to launchpad.
.PHONY: upload
upload: deb_dist/signed
	cd deb_dist && dput $(PPA) $(CHANGES_FILENAME)

# Run unit tests.
.PHONY: test
test:
	tox

.PHONY: clean
clean:
	rm -rf dist
	rm -rf build
	rm -rf .tox
	rm -rf .eggs
	rm -rf deb_dist
	rm -rf posix_spawn/__pycache__
	find -iname '*.pyc' -delete
