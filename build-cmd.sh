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

mkdir -p "$stage/include/OpenEXR"
mkdir -p "$stage/lib/release"

srcdir="$top/openexr"
builddir="$top/build"

mkdir -p $builddir
mkdir -p $stage

pushd $builddir

case "$AUTOBUILD_PLATFORM" in
windows*)
        cmake $(cygpath -w "$srcdir") -DCMAKE_INSTALL_PREFIX=$(cygpath -w "$top/release")
        cmake --build . --target install --config Release
        cp -v ../release/lib/*.lib "$stage/lib/release/"
        mkdir -p "$stage/bin"
        cp -v ../release/bin/*.dll "$stage/bin"
;;
darwin*|linux64*)
        
        cmake $srcdir --install-prefix "$top/release"
        cmake --build . --target install --config Release

	# TODO - add .so support for linux
        cp -v "$top"/release/lib/*.dylib "$stage/lib/release/"
;;
esac

cp -rv "$top/release/include/OpenEXR" "$stage/include/OpenEXR"
cp -rv "$top/release/include/Imath" "$stage/include/Imath"

popd

mkdir -p "$stage/LICENSES"
cp "$top/LICENSE" "$stage/LICENSES/openexr.txt"
cp -v $top/VERSION.txt $stage/VERSION.txt

