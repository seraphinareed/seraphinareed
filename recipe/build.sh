#!/bin/bash

set -e -o pipefail

if [[ "$(uname)" = Darwin ]] ; then
    export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

# Needed for jpeg on Linux/GCC7:
export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"

mkdir forgebuild
cd forgebuild
meson \
    --buildtype=release \
    --prefix="$PREFIX" \
    --backend=ninja \
    -Ddocs=false \
    -Dgir=true \
    -Dgio_sniffing=false \
    -Dinstalled_tests=false \
    -Dlibdir=lib \
    -Drelocatable=true \
    ..
ninja -j$CPU_COUNT -v
ninja install

cd $PREFIX
rm -rf share/gtk-doc
find . -name '*.la' -delete
