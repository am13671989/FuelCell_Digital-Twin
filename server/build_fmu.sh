#!/bin/sh
# Builds one Linux FMU per class listed in $MODELS into /fmu
set -e
mkdir -p /fmu /tmp/b && cd /tmp/b
for M in $MODELS; do
  printf 'loadFile("/src/FCDT/package.mo"); getErrorString();\nbuildModelFMU(%s, version="2.0", fmuType="cs", fileNamePrefix="%s"); getErrorString();\n' "$M" "$M" > b.mos
  omc b.mos
  cp "$M.fmu" /fmu/
done
ls -l /fmu
