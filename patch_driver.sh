#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
# APPLE_SMC_DRIVER_GIT_URL=https://github.com/Redecorating/mbp-16.1-linux-wifi
# APPLE_SMC_REPO_NAME=mbp-16.1-linux-wifi
# APPLE_SMC_DRIVER_BRANCH_NAME=main
# APPLE_SMC_DRIVER_COMMIT_HASH=0f18a8ee0e2eb7893222e3d0f433f75ce689aa91

APPLE_SMC_DRIVER_GIT_URL=https://github.com/AdityaGarg8/linux-t2-patches
APPLE_SMC_REPO_NAME=linux-t2-patches
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=9dcb1e2d259c8bcdb3242000a552e21f6fabf8cd

# TMP_DIR=~/temp_dir
TMP_DIR=/tmp/temp_dir
REPO_PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCHES_DIR=${PATCHES_DIR:-$REPO_PWD/patches}

mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}" || exit

rm -rf "${PATCHES_DIR}"
mkdir -p "${PATCHES_DIR}"

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
cd "${APPLE_SMC_REPO_NAME}" || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*.patch" | sort | grep -v "8002-asahilinux-hci_bcm4377-patchset.patch")

rm -rf "${TMP_DIR}"
