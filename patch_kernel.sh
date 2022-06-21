#!/bin/bash

RPMBUILD_PATH=${RPMBUILD_PATH:-/root/rpmbuild}
SOURCES_PATH=${RPMBUILD_PATH}/SOURCES
SPECS_PATH=${RPMBUILD_PATH}/SPECS
SPECFILE="${SPECS_PATH}/kernel.spec"

# Check for at least patch
if [ "$#" -lt 1 ]; then
  echo "usage: $0 [ /path/to/patch/ ] [ description ]"
  exit 1
fi
PATCHDIR=$1

PATCH="$(basename "$PATCHDIR")"

cd "${SOURCES_PATH}" || exit

# If adding patch from outside the source tree move it to the source tree
# shellcheck disable=SC2010
if ! ls | grep -q "$PATCH"; then
  cp "$PATCHDIR" "$SOURCES_PATH"/
fi

if grep -q "$PATCH" "$SPECFILE"; then
  echo "$PATCH already in kernel.spec"
  exit 1
fi

# ID number of the last patch in kernel.spec
LPATCH_ID=$(grep ^Patch "$SPECFILE" | tail -n2 | head -n1 | awk '{ print $1 }' | sed s/Patch// | sed s/://)

# ID of the next patch to be added to kernel.spec
NPATCH_ID=$((LPATCH_ID + 1 ))

# Add patch with new id at the end of the list of patches
sed -i "/^Patch$LPATCH_ID:\ /a#\ $DESC\nPatch$NPATCH_ID:\ $PATCH" "$SPECFILE"
sed -i "/^ApplyOptionalPatch[[:space:]]p/i ApplyOptionalPatch\ $PATCH" "$SPECFILE"
sed -i "s/patch_command='patch -p1 -F1 -s'/patch_command='patch -p1 -F2 -s'/g" "$SPECFILE"
