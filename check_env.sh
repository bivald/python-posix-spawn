#!/usr/bin/env bash

set -e

if ! pip list | grep -q 'cffi (0.8.2)';
then
    echo "Build requires cffi 0.8.2 (exactly) to be installed."
    exit 1
fi

if ! which py2dsc;
then
    echo "Build requires stdeb to be installed"
    exit 1
fi