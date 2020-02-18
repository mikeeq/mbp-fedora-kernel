#!/bin/sh

# Facilitates the addition of a new patch to the source tree.
# -- Moves patch to tree
# -- Adds  patch to kernel.spec list of patches
# -- Adds patch to git
# -- change buildid macro to the name of the patch being added

# Base directory is relative to where the script is.
BASEDIR="$(dirname "$(cd $(dirname $BASH_SOURCE[0]) && pwd)")"
pushd $BASEDIR > /dev/null
# Check for at least patch
if [ "$#" -lt 1 ]; then
    echo "usage: $0 [ /path/to/patch/ ] [ description ]"
    exit 1
fi
PATCHDIR=$1
DESC=$2
PATCH="$(basename "$PATCHDIR")"
# Kernel.spec file in the current tree
SPECFILE="$BASEDIR/kernel.spec"
# If adding patch from outside the source tree move it to the source tree
if [ -z "$(ls | grep $PATCH)" ]; then
    cp $PATCHDIR $BASEDIR/
fi

if [ ! -z "$(grep $PATCH $SPECFILE)" ]
then
    echo "$PATCH already in kernel.spec"
    exit 1
fi
# ID number of the last patch in kernel.spec
LPATCH_ID=$(grep ^Patch $SPECFILE | tail -n1 | awk '{ print $1 }' | sed s/Patch// | sed s/://)
# ID of the next patch to be added to kernel.spec
NPATCH_ID=$(($LPATCH_ID + 1 ))
# Add patch with new id at the end of the list of patches
sed -i "/^Patch$LPATCH_ID:\ /a#\ $DESC\nPatch$NPATCH_ID:\ $PATCH" $SPECFILE
# Add it to git
git add $PATCH
BUILDID_PATCH="$(echo $PATCH | sed 's/\-/\_/g' )"
sed -i "s/^.*define buildid .*$/%define buildid .$BUILDID_PATCH/" $SPECFILE
popd > /dev/null
