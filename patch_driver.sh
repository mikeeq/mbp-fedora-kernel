#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
APPLE_SMC_DRIVER_GIT_URL=https://github.com/jamlam/mbp-16.1-linux-wifi
APPLE_SMC_REPO_NAME=mbp-16.1-linux-wifi
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=843ecfcaaec0a10707d447ac6d1840db940a9d29
APPLE_WIFI_DRIVER_GIT_URL=https://github.com/aunali1/linux-mbp-arch
APPLE_WIFI_REPO_NAME=linux-mbp-arch
APPLE_WIFI_DRIVER_BRANCH_NAME=master
APPLE_WIFI_DRIVER_COMMIT_HASH=9511d5ed2ae0e851dd6a82843daefb2be7d5e212

# TMP_DIR=~/temp_dir
TMP_DIR=/tmp/temp_dir
REPO_PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCHES_DIR=${PATCHES_DIR:-$REPO_PWD/patches}

mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}" || exit

mkdir -p "${PATCHES_DIR}"

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
cd "${APPLE_SMC_REPO_NAME}" || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*patch" | grep -v ZEN | grep -v wifi-bigsur | grep -v brcmfmac | sort)

### Apple WIFI fixes
git clone --single-branch --branch ${APPLE_WIFI_DRIVER_BRANCH_NAME} ${APPLE_WIFI_DRIVER_GIT_URL}
cd "${APPLE_WIFI_REPO_NAME}" || exit
git checkout ${APPLE_WIFI_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find "${APPLE_WIFI_REPO_NAME}" -type f -name "*patch" | grep brcmfmac | sort)

rm -rf "${TMP_DIR}"
