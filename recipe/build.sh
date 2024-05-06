#!/bin/bash

set -e -o pipefail

if [[ "$(uname)" = Darwin ]] ; then
    export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

./configure \
    --prefix=$PREFIX \
    --libdir=$PREFIX/lib \
    --enable-introspection

make V=1 -j$CPU_COUNT
make install

cd $PREFIX
rm -rf share/gtk-doc
find . -name '*.la' -delete
