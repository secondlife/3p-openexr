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

# remove_cxxstd
source "$(dirname "$AUTOBUILD_VARIABLES_FILE")/functions"

mkdir -p "$stage/include" "$stage/lib/release" $builddir

build=${AUTOBUILD_BUILD_ID:=0}
version=$(cat VERSION.txt)
echo "${version}.${build}" > "${stage}/VERSION.txt"

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

pushd $builddir

#exit

case "$AUTOBUILD_PLATFORM" in
        windows*)
        cmake .. -DCMAKE_INSTALL_PREFIX=../release
        cmake --build . --target install --config Release
        cp -v ../release/lib/*.lib "$stage/lib/release/"
        cp -rv ../release/bin/*.dll "$stage/bin"
;;
darwin*)
        cmake .. --install-prefix ../release
        cmake --build . --target install --config Release

        cp -v ../release/lib/*.a "$stage/lib/release/"
;;
linux64)
        cmake "$top/openexr" -DOPENEXR_LIB_SUFFIX= -DBUILD_SHARED_LIBS=OFF --install-prefix "$top/release"
        cmake --build . -j$(nproc) --target install --config Release
        cp -a $top/release/lib/{libIex.a,libIlmThread.a,libOpenEXR.a,libOpenEXRCore.a,libOpenEXRUtil.a} "$stage/lib/release/"
;;

esac

popd

cp -ra "release/include/OpenEXR" "$stage/include"
cp -ra "release/include/Imath" "$stage/include"

mkdir -p "$stage/LICENSES"
cp LICENSE "$stage/LICENSES/OpenEXR.txt"
