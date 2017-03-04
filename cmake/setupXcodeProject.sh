#!/bin/bash

# where am I?
CURDIR=$(pwd)

BUILDDIR=../../openExternalsBuild-Xcode

if [ -d "$BUILDDIR" ] 
then
	echo "Build directory exists... Removing $BUILDDIR"
	rm -rf $BUILDDIR
else
	echo "Build directory not found... Making $BUILDDIR"
	
fi

# either way I am remaking this directory.
mkdir $BUILDDIR

# move into the build directory and run cmake.
cd $BUILDDIR
echo "Now in $(pwd)... Create openExternals build project for $BUILDTYPE."
cmake -GXcode ../openExternals

# let's go back in case I need to re-run this script.
cd $CURDIR