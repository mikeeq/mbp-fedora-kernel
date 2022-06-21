#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
APPLE_SMC_DRIVER_GIT_URL=https://github.com/zeroday0619/linux-t2-patches.git
APPLE_SMC_REPO_NAME=linux-t2-patches
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=8fc5876637f79fbe20db09c95cb0300d75ed4475

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
rm 100*
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${PATCHES_DIR}"/"${file##*/}"
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*.patch" | sort)

rm -rf "${TMP_DIR}"
