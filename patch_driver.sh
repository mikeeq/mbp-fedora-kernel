#!/bin/bash

set -eu -o pipefail

# set -x

### Apple T2 drivers commit hashes
APPLE_SMC_DRIVER_GIT_URL=https://github.com/AdityaGarg8/linux-t2-patches
APPLE_SMC_REPO_NAME=linux-t2-patches
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=7618e312f014de761fe35940f24097ab3b962d8d

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
done < <(find "${APPLE_SMC_REPO_NAME}" -type f -name "*patch" | grep -v 1001 | grep -v 1002 | grep -v 1004 | sort)

rm -rf "${TMP_DIR}"

# Patch2: 1004-add-modalias-to-apple-bce.patch
# + case "$patch" in
# + patch -p1 -F2 -s
# The text leading up to this was:
# --------------------------
# |From 153b587ed53135eaf244144f6f8bdd5a0fe6b69e Mon Sep 17 00:00:00 2001
# |From: Redecorating <69827514+Redecorating@users.noreply.github.com>
# |Date: Fri, 24 Dec 2021 18:12:25 +1100
# |Subject: [PATCH 1/1] add modalias to apple-bce
# |
# |---
# | drivers/staging/apple-bce/apple_bce.c     |  1 +
# | 1 files changed, 1 insertions(+), 0 deletions(-)
# |
# |diff --git a/drivers/staging/apple-bce/apple_bce.c b/drivers/staging/apple-bce/apple_bce.c
# |index a6a656f..8cfbd3f 100644
# |--- a/drivers/staging/apple-bce/apple_bce.c
# |+++ b/drivers/staging/apple-bce/apple_bce.c
# --------------------------
# File to patch:
# Skip this patch? [y]
# 1 out of 1 hunk ignored
# error: Bad exit status from /var/tmp/rpm-tmp.83tGk6 (%prep)


# RPM build errors:
#     Macro expanded in comment on line 188: %define with_kabichk   %{?_without_kabichk:   0} %{?!_without_kabichk:   1}

#     Bad exit status from /var/tmp/rpm-tmp.83tGk6 (%prep)
