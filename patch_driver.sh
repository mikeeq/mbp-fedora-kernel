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
#APPLE_SMC_DRIVER_COMMIT_HASH=651c7122edf99e90dc0e4976e7d30b9e227bbb09
#APPLE_SMC_DRIVER_COMMIT_HASH=2e784523aad2f29c41f7881abedf8913acb1c279
APPLE_SMC_DRIVER_COMMIT_HASH=b946df050a82750b7877d6ba3ef9220165b5ef3a
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
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*.patch" | sort | grep -v "0001-arch-additions.patch")

# curl -sL https://raw.githubusercontent.com/Redecorating/mbp-16.1-linux-wifi/main/8002-asahilinux-hci_bcm4377-patchset.patch -o "${PATCHES_DIR}"/9001-asahilinux-hci_bcm4377-patchset.patch

rm -rf "${TMP_DIR}"
