#!/usr/bin/env bash
xsltproc --nonet --novalid x2t.xsl <(curl -s "$1") > out.tex
