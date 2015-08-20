# Copyright (c) 2015 Metaswitch Networks

# Recursive wildcard function.
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

VERSION := 0.2
PYTHON_FILES := $(call rwildcard,posix_spawn/,*.py) $(wildcard *.py)
CDEF_FILES := $(wildcard posix_spawn/c/*.[ch])
DEB_FILES := debian/* debian/source/*
SOURCE_FILES := $(PYTHON_FILES) $(CDEF_FILES) LICENSE MANIFEST.in README.md
SOURCE_DEB_OUTPUT := deb_dist/posix-spawn_0.2-1.dsc \
                     deb_dist/posix-spawn_0.2-1_source.changes \
                     deb_dist/posix-spawn_0.2.orig.tar.gz \
                     deb_dist/posix-spawn_0.2-1.debian.tar.gz

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
	python setup.py --command-packages=stdeb.command sdist_dsc

.PHONY: src-deb
src-deb: $(SOURCE_DEB_OUTPUT)

.PHONY: signed-src-deb
signed-src-deb: deb_dist/signed
deb_dist/signed: $(SOURCE_DEB_OUTPUT)
ifndef DEBSIGN_KEYID
	$(error DEBSIGN_KEYID is undefined)
endif
	cd deb_dist; debsign *.changes && touch signed

deb_dist/python-posix-spawn_0.2-1_amd64.deb: $(SOURCE_FILES) $(DEB_FILES)
	./check_env.sh
	python setup.py --command-packages=stdeb.command bdist_deb

.PHONY: deb
deb: deb_dist/python-posix-spawn_0.2-1_amd64.deb

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
	find -iname '*.pyc' -delete