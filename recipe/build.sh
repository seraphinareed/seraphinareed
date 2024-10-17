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
    -Dlibdir=lib \
    -Ddocs=false \
    -Dgir=true \
    -Drelocatable=true \
    -Dinstalled_tests=false \
    ..
ninja -j$CPU_COUNT -v
ninja install

cd $PREFIX
rm -rf share/gtk-doc
find . -name '*.la' -delete
