#!/bin/bash

set -e -o pipefail

if [[ "$(uname)" = Darwin ]] ; then
    export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

# Needed for jpeg on Linux/GCC7:
export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"

meson_options=(
    --buildtype=release
    --prefix="$PREFIX"
    --backend=ninja
    -Ddocs=false
    -Dgir=true
    -Dgio_sniffing=false
    -Dinstalled_tests=false
    -Dlibdir=lib
    -Drelocatable=true
)

if [[ $(uname) == Darwin ]] ; then
    # Disable X11 since our default Mac environment doesn't provide it (and
    # apparently the build scripts assume that it will be there).
    #
    # Disable manpages since the macOS xsltproc doesn't want to load
    # docbook.xsl remotely in --nonet mode.
    meson_options+=(-Dx11=false -Dman=false)
fi

mkdir forgebuild
cd forgebuild

meson "${meson_options[@]}" ..
ninja -j$CPU_COUNT -v
ninja install

cd $PREFIX
rm -rf share/gtk-doc
find . -name '*.la' -delete
