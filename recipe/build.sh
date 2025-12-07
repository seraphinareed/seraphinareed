#!/bin/bash

set -xeo pipefail

if [[ "$target_platform" = osx-* ]] ; then
    # The -dead_strip_dylibs option breaks g-ir-scanner in this package: the
    # scanner links a test executable to find paths to dylibs, but with this
    # option the linker strips them out. The resulting error message is
    # "ERROR: can't resolve libraries to shared libraries: ...".
    export LDFLAGS="$(echo $LDFLAGS |sed -e "s/-Wl,-dead_strip_dylibs//g")"
    export LDFLAGS_LD="$(echo $LDFLAGS_LD |sed -e "s/-dead_strip_dylibs//g")"
fi

meson_options=(
    --buildtype=release
    --backend=ninja
    -Ddocs=false
    -Dgio_sniffing=false
    -Dinstalled_tests=false
    -Dlibdir=lib
    -Drelocatable=true
    -Dintrospection=enabled
)


if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  (
    mkdir -p native-build
    pushd native-build

    export CC=$CC_FOR_BUILD
    export AR=($CC_FOR_BUILD -print-prog-name=ar)
    export NM=($CC_FOR_BUILD -print-prog-name=nm)
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig
    unset _CONDA_PYTHON_SYSCONFIGDATA_NAME

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS

    meson "${meson_options[@]}" --prefix=$BUILD_PREFIX ..
    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$PREFIX/libexec/gi-cross-launcher-save.sh
    ninja -j$CPU_COUNT -v
    ninja install
    popd
  )
  export GI_CROSS_LAUNCHER=$PREFIX/libexec/gi-cross-launcher-load.sh
fi

mkdir forgebuild
cd forgebuild

if [[ "$target_platform" == osx-* ]] ; then
    # Disable X11 since our default Mac environment doesn't provide it (and
    # apparently the build scripts assume that it will be there).
    #
    # Disable manpages since the macOS xsltproc doesn't want to load
    # docbook.xsl remotely in --nonet mode.
    meson_options+=(-Dx11=false -Dman=false)
fi


# This bit essentially copy/pasted from glib-feedstock:
if [[ "$target_platform" == "osx-arm64" && "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config
fi

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig:$BUILD_PREFIX/lib/pkgconfig

meson "${meson_options[@]}" $MESON_ARGS --prefix=$PREFIX ..
ninja -j$CPU_COUNT -v
ninja install

cd $PREFIX
rm -rf share/gtk-doc
find . -name '*.la' -delete
