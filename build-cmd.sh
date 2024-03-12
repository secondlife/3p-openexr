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

echo $top
echo $stage

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

# remove_cxxstd
source "$(dirname "$AUTOBUILD_VARIABLES_FILE")/functions"

build=${AUTOBUILD_BUILD_ID:=0}

mkdir -p "$stage/lib/release"

srcdir="$top/openexr"
builddir="$top/build"

mkdir -p $builddir
mkdir -p $stage

pushd $builddir

case "$AUTOBUILD_PLATFORM" in
windows*)
        cmake $(cygpath -w "$srcdir") -DCMAKE_INSTALL_PREFIX=$(cygpath -w "$top/release")
        cmake --build . --target install --config Release -j
        cp -v ../release/lib/*.lib "$stage/lib/release/"
        cp -v ../release/bin/*.dll "$stage/lib/release/"
;;
darwin*)
        cmake $srcdir --install-prefix "$top/release" -DOPENEXR_FORCE_INTERNAL_IMATH:BOOL=ON -DBUILD_SHARED_LIBS:BOOL=OFF -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
        cmake --build . --target install --config Release -j

        cp -v "$top"/release/lib/*.a "$stage/lib/release/"

        # check architectures to verify universal build worked, should contain "x86_64 arm64"
        built_archs="$(lipo -archs "$stage/lib/release/libOpenEXR-3_2.a")"
        echo "checking built architectures in libOpenEXR-3_2.a: '$built_archs'.  expected 'x86_64 arm64'"
        test 'x86_64 arm64' = "$built_archs"
;;
linux64*)
        cmake $srcdir --install-prefix "$top/release" -DOPENEXR_FORCE_INTERNAL_IMATH:BOOL=ON -DBUILD_SHARED_LIBS:BOOL=OFF
        cmake --build . --target install --config Release -j

        cp -v "$top"/release/lib/*.a "$stage/lib/release/"
;;
esac

cp -rv "$top/release/include" "$stage"

popd

mkdir -p "$stage/LICENSES"
cp "$top/LICENSE" "$stage/LICENSES/openexr.txt"
cp -v $top/VERSION.txt $stage/VERSION.txt

