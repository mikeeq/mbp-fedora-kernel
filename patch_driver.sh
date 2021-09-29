#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
APPLE_SMC_DRIVER_GIT_URL=https://github.com/jamlam/mbp-16.1-linux-wifi
APPLE_SMC_REPO_NAME=mbp-16.1-linux-wifi
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=fb6d3696ad9aa5f145d344081817b251637dde02
APPLE_BT_PATCH_GIT_COMMIT_HASH=882b45955e877b6416b8b3fb3f9ecdf98f9c41b7        # https://github.com/jamlam/mbp-16.1-linux-wifi
APPLE_BT_PATCH_GIT_FILENAME=9001-bluetooth-disable-read-LE-MinMax-Tx-Power.patch
APPLE_BT_PATCH_GIT_URL=https://raw.githubusercontent.com/jamlam/mbp-16.1-linux-wifi/${APPLE_BT_PATCH_GIT_COMMIT_HASH}/${APPLE_BT_PATCH_GIT_FILENAME}

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
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*patch" | grep -v ZEN | sort)

### BT Patch
curl -sL "${APPLE_BT_PATCH_GIT_URL}" -o "${PATCHES_DIR}"/wifi-bigsur.patch

rm -rf "${TMP_DIR}"
