#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

top="$(pwd)"
stage="$(pwd)/stage"
srcdir="$top/openexr"
builddir="$top/build"

mkdir -p "$stage/include" "$stage/lib/release" "$builddir"

# remove_cxxstd
source "$(dirname "$AUTOBUILD_VARIABLES_FILE")/functions"

build=${AUTOBUILD_BUILD_ID:=0}
version=$(cat VERSION.txt)
echo "${version}.${build}" > "${stage}/VERSION.txt"

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

pushd $builddir

case "$AUTOBUILD_PLATFORM" in
windows*)
        cmake ../openexr -DCMAKE_INSTALL_PREFIX=../release
        cmake --build . --target install --config Release -j
        cp -v ../release/lib/*.lib "$stage/lib/release/"
        cp -rv ../release/bin/*.dll "$stage/lib/release/"
;;
darwin*)
        cmake ../openexr --install-prefix "$top/release" -DOPENEXR_FORCE_INTERNAL_IMATH:BOOL=ON -DBUILD_SHARED_LIBS:BOOL=OFF -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
        cmake --build . --target install --config Release -j

        cp -v "$top"/release/lib/*.a "$stage/lib/release/"

        # check architectures to verify universal build worked, should contain "x86_64 arm64"
        built_archs="$(lipo -archs "$stage/lib/release/libOpenEXR-3_2.a")"
        echo "checking built architectures in libOpenEXR-3_2.a: '$built_archs'.  expected 'x86_64 arm64'"
        test 'x86_64 arm64' = "$built_archs"
;;
linux64)
        cmake "../openexr"  --install-prefix "$top/release" -DOPENEXR_LIB_SUFFIX= -DBUILD_SHARED_LIBS=OFF
        cmake --build . -j$(nproc) --target install --config Release
        cp -a $top/release/lib/{libIex.a,libIlmThread.a,libOpenEXR.a,libOpenEXRCore.a,libOpenEXRUtil.a} "$stage/lib/release/"
;;

esac

cp -rv ../release/include/OpenEXR "$stage/include/OpenEXR"
cp -rv ../release/include/Imath "$stage/include/Imath"

popd

mkdir -p "$stage/LICENSES"
cp "LICENSE" "$stage/LICENSES/OpenEXR.txt"
