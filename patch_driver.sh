#!/bin/bash

set -eu -o pipefail

# set -x

APPLE_BCE_REPOSITORY=https://github.com/kekrby/apple-bce.git
APPLE_IBRIDGE_REPOSITORY=https://github.com/Redecorating/apple-ib-drv.git

RPMBUILD_PATH=${RPMBUILD_PATH:-/root/rpmbuild}
KERNEL_PATH=${RPMBUILD_PATH}/SOURCES

APPLE_SMC_DRIVER_GIT_URL=https://github.com/t2linux/linux-t2-patches
APPLE_SMC_REPO_NAME=linux-t2-patches
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=42eefd1c0331c20efedc5674508c32d52575f723

# TMP_DIR=~/temp_dir
TMP_DIR=/tmp/temp_dir
REPO_PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCHES_DIR=${PATCHES_DIR:-$REPO_PWD/patches}

mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}" || exit

rm -rf "${PATCHES_DIR}"
mkdir -p "${PATCHES_DIR}"

git clone --depth 1 "${APPLE_BCE_REPOSITORY}" "${KERNEL_PATH}/drivers/staging/apple-bce"
git clone --depth 1 "${APPLE_IBRIDGE_REPOSITORY}" "${KERNEL_PATH}/drivers/staging/apple-ibridge"

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
cd "${APPLE_SMC_REPO_NAME}" || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*.patch" | sort | grep -v -e 1001 -e 1002)

rm -rf "${TMP_DIR}"
