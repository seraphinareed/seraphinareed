#!/bin/bash

set -e -o pipefail

if [[ "$(uname)" = Darwin ]] ; then
    export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

# Needed for jpeg on Linux/GCC7:
export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"

./configure \
    --prefix=$PREFIX \
    --libdir=$PREFIX/lib \
    --enable-introspection

make V=1 -j$CPU_COUNT
make install

cd $PREFIX
rm -rf share/gtk-doc
find . -name '*.la' -delete
