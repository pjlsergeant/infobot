#!/bin/sh

export COPY_EXTENDED_ATTRIBUTES_DISABLE=1
make clean
perl Makefile.PL
make
make dist
