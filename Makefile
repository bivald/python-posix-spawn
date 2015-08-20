# Copyright (c) 2015 Metaswitch Networks

# Recursive wildcard function.
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

MAINTAINER := Shaun Crampton <shaun@projectcalico.org>
VERSION := 0.2
DEBIAN_VERSION := 3
FULL_VERSION := $(VERSION)-$(DEBIAN_VERSION)

PYTHON_FILES := $(call rwildcard,posix_spawn/,*.py) $(wildcard *.py)
CDEF_FILES := $(wildcard posix_spawn/c/*.[ch])
DEB_FILES := debian/*
SOURCE_FILES := $(PYTHON_FILES) $(CDEF_FILES) LICENSE MANIFEST.in README.md
SOURCE_DEB_OUTPUT := deb_dist/posix-spawn_$(FULL_VERSION).dsc \
                     deb_dist/posix-spawn_$(FULL_VERSION)_source.changes \
                     deb_dist/posix-spawn_$(VERSION).orig.tar.gz \
                     deb_dist/posix-spawn_$(FULL_VERSION).debian.tar.gz

.PHONY: all
all: signed-src-deb

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

$(SOURCE_DEB_OUTPUT): $(SOURCE_FILES) $(DEB_FILES)
	./check_env.sh
	python setup.py --command-packages=stdeb.command sdist_dsc \
	    --debian-version $(DEBIAN_VERSION) \
	    --maintainer "$(MAINTAINER)" \
	    --suite trusty \
	    --copyright-file debian/copyright \
	    --build-depends "python-cffi (>=0.8.2)" \
	    --depends "python-cffi (>=0.8.2)"

.PHONY: src-deb
src-deb: $(SOURCE_DEB_OUTPUT)

.PHONY: lint
lint: src-deb
	cd deb_dist; lintian -i posix-spawn_$(FULL_VERSION)_source.changes

.PHONY: signed-src-deb
signed-src-deb: deb_dist/signed
deb_dist/signed: $(SOURCE_DEB_OUTPUT)
ifndef DEBSIGN_KEYID
	$(error DEBSIGN_KEYID is undefined)
endif
	cd deb_dist; debsign -k $(DEBSIGN_KEYID) *.changes && touch signed

deb_dist/python-posix-spawn_$(FULL_VERSION)_amd64.deb: $(SOURCE_FILES) $(DEB_FILES)
	./check_env.sh
	python setup.py --command-packages=stdeb.command bdist_deb --debian-version $(DEBIAN_VERSION)

.PHONY: deb
deb: deb_dist/python-posix-spawn_$(FULL_VERSION)_amd64.deb

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
