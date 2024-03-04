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

srcdir = "$top/openexr"
builddir = "$top/build"

mkdir -p $builddir
mkdir -p $stage

echo $builddir
echo $srcdir

pushd

cd $builddir

echo "Building for $AUTOBUILD_PLATFORM"

case "$AUTOBUILD_PLATFORM" in
        windows*)
        cmake .. -DCMAKE_INSTALL_PREFIX=../release
        cmake --build . --target install --config Release
        cp -v ../release/lib/*.lib "$stage/lib/release/"
        cp -rv ../release/bin/*.dll "$stage/bin"
;;
darwin*|linux64*)
        
        cmake .. --install-prefix ../release
        cmake --build . --target install --config Release

        cp -v ../release/lib/*.a "$stage/lib/release/"
;;
esac

cp -rv ../release/include/OpenEXR "$stage/include/OpenEXR"
cp -rv ../release/include/Imath "$stage/include/Imath"

popd

mkdir -p "$stage/LICENSES"
cp "$top/LICENSE" "$stage/LICENSES/openexr.txt"
