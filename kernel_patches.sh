#!/bin/bash

set -eu -o pipefail

# set -x

# APPLE_BCE_REPOSITORY=https://github.com/kekrby/apple-bce.git
# APPLE_IBRIDGE_REPOSITORY=https://github.com/Redecorating/apple-ib-drv.git

APPLE_SMC_DRIVER_GIT_URL=https://github.com/t2linux/linux-t2-patches
APPLE_SMC_REPO_NAME=linux-t2-patches
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=98e76c4c5bcdb5ce5a3752f68c83e0bcea953654

TMP_DIR=/tmp/tmp_dir
REPO_PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCHES_DIR=${PATCHES_DIR:-$REPO_PWD/patches}

rm -rf "${PATCHES_DIR}"
mkdir -p "${PATCHES_DIR}"

mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}" || exit

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
cd "${APPLE_SMC_REPO_NAME}" || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*.patch" | sort)

curl -Ls "https://raw.githubusercontent.com/t2linux/linux-t2-patches/5d7fec1df97018a29147917531b248992b5368e9/8001-asahilinux-wifi-patchset.patch" -o "${PATCHES_DIR}/8001-asahilinux-wifi-patchset.patch"

# curl -Ls "https://raw.githubusercontent.com/t2linux/linux-t2-patches/98e76c4c5bcdb5ce5a3752f68c83e0bcea953654/3008-applesmc-make-applesmc_remove-void.patch" -o "${PATCHES_DIR}/3008-applesmc-make-applesmc_remove-void.patch"
# curl -Ls "https://raw.githubusercontent.com/t2linux/linux-t2-patches/98e76c4c5bcdb5ce5a3752f68c83e0bcea953654/3009-applesmc-battery-charge-limiter.patch" -o "${PATCHES_DIR}/3009-applesmc-battery-charge-limiter.patch"

rm -rf "${TMP_DIR}"
