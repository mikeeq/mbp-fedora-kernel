#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
APPLE_SMC_DRIVER_GIT_URL=https://github.com/aunali1/linux-mbp-arch
APPLE_SMC_DRIVER_BRANCH_NAME=master
APPLE_SMC_DRIVER_COMMIT_HASH=1bd10dc764c6be5fbdda848bc56ecd746774cfb2
APPLE_WIFI_BIGSUR_PATCH_GIT_COMMIT_HASH=46e4665e286862d76d29701a334515a77734c58f        # https://github.com/jamlam/mbp-16.1-linux-wifi
APPLE_WIFI_BIGSUR_PATCH_GIT_URL=https://raw.githubusercontent.com/jamlam/mbp-16.1-linux-wifi/${APPLE_WIFI_BIGSUR_PATCH_GIT_COMMIT_HASH}/wifi-bigsur.patch
# TMP_DIR=~/temp_dir
TMP_DIR=/tmp/temp_dir
REPO_PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCHES_DIR=${PATCHES_DIR:-$REPO_PWD/patches}

mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}" || exit

mkdir -p "${PATCHES_DIR}"

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
cd linux-mbp-arch || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find linux-mbp-arch -type f -name "*patch" | grep -v iwlwifi | grep -v brcmfmac | grep -v i915 | grep -v ZEN | grep -v x86 | sort)

### WiFi 16.2 Patch
curl -sL "${APPLE_WIFI_BIGSUR_PATCH_GIT_URL}" -o "${PATCHES_DIR}"/wifi-bigsur.patch

rm -rf "${TMP_DIR}"
