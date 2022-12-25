#!/bin/bash

set -eu -o pipefail

# set -x

# APPLE_BCE_REPOSITORY=https://github.com/kekrby/apple-bce.git
# APPLE_IBRIDGE_REPOSITORY=https://github.com/Redecorating/apple-ib-drv.git

APPLE_SMC_DRIVER_GIT_URL=https://github.com/t2linux/linux-t2-patches
APPLE_SMC_REPO_NAME=linux-t2-patches
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=5c2a3930cbc83bab1381239cc49c1047db94e753

# TMP_DIR=~/tmp_dir
TMP_DIR=/tmp/tmp_dir
# TMP_REPOS_DIR=/tmp/tmp_repos_dir
REPO_PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCHES_DIR=${PATCHES_DIR:-$REPO_PWD/patches}

rm -rf "${PATCHES_DIR}"
mkdir -p "${PATCHES_DIR}"

# mkdir -p "${TMP_REPOS_DIR}/"

# cd "${TMP_REPOS_DIR}/" || exit
# mkdir -p apple-bce
# cd apple-bce
# git init

# git clone --depth 1 "${APPLE_BCE_REPOSITORY}" "./drivers/staging/apple-bce"
# rm -rf "./drivers/staging/apple-bce/.git"
# git add .
# git diff --cached > "${PATCHES_DIR}/1001-apple-bce-driver.patch"

# cd "${TMP_REPOS_DIR}/" || exit
# mkdir -p apple-ibridge
# cd apple-ibridge
# git init

# git clone --depth 1 "${APPLE_IBRIDGE_REPOSITORY}" "./drivers/staging/apple-ibridge"
# rm -rf "./drivers/staging/apple-ibridge/.git"
# git add .
# git diff --cached > "${PATCHES_DIR}/1002-apple-ibridge-driver.patch"

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
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*.patch" | sort | grep -v 7001)

rm -rf "${TMP_DIR}"
# rm -rf "${TMP_REPOS_DIR}"
