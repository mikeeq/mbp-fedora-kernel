#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
APPLE_SMC_DRIVER_GIT_URL=https://github.com/jamlam/mbp-16.1-linux-wifi
APPLE_SMC_REPO_NAME=mbp-16.1-linux-wifi
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=edeb47a4363d3647ea543738b27f3962ff245197

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
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*patch" | grep -v ZEN | grep -v 9001 | grep -v intel-lpss.patch | sort)

# Add EFI NVRAM patch from newer commit
curl -L https://raw.githubusercontent.com/jamlam/mbp-16.1-linux-wifi/6ca55fd96abf9fb47338f52cdd44659c0b3ef935/efi.patch -o "${PATCHES_DIR}"/efi.patch
# Add 4010-HID-apple-Add-ability-to-use-numbers-as-function-key.patch from @Redecorating
curl -L https://raw.githubusercontent.com/Redecorating/mbp-16.1-linux-wifi/62f304f30baa1975ac8623aaf00e6847bfa4f249/4010-HID-apple-Add-ability-to-use-numbers-as-function-key.patch -o "${PATCHES_DIR}"/4010-tb.patch
rm -rf "${TMP_DIR}"
