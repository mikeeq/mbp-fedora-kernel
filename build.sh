#!/bin/bash

set -eu -o pipefail

## Update fedora docker image tag, because kernel build is using `uname -r` when defining package version variable
FEDORA_KERNEL_GIT_URL=https://src.fedoraproject.org/rpms/kernel.git
FEDORA_KERNEL_VERSION=5.5.7
FEDORA_KERNEL_BRANCH_NAME=f31
FEDORA_KERNEL_COMMIT_HASH=348755927b84cae22c2438987ee2440a019a55bd      # https://src.fedoraproject.org/rpms/kernel/commits/f31

### Debug commands
echo "FEDORA_KERNEL_VERSION=$FEDORA_KERNEL_VERSION"
echo "FEDORA_KERNEL_BRANCH_NAME=$FEDORA_KERNEL_BRANCH_NAME"
echo "FEDORA_KERNEL_COMMIT_HASH=$FEDORA_KERNEL_COMMIT_HASH"
pwd
ls
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq
# git clone --depth 1 --single-branch --branch v5.1.19 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

### Dependencies
dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools zip curl

### Clone Fedora Kernel git repo
git clone --single-branch --branch $FEDORA_KERNEL_BRANCH_NAME ${FEDORA_KERNEL_GIT_URL}
cd kernel
## Cleanup
rm -rfv ./*.rpm
rm -rf ~/rpmbuild/*
git reset --hard $FEDORA_KERNEL_BRANCH_NAME
git checkout $FEDORA_KERNEL_BRANCH_NAME
git branch -d fedora_patch_src &>/dev/null || true
fedpkg clean
## Change branch
git checkout $FEDORA_KERNEL_COMMIT_HASH
git reset --hard $FEDORA_KERNEL_COMMIT_HASH
git checkout -b fedora_patch_src
dnf -y builddep kernel.spec

### Fixes for kernel.spec
# sed -i "s/Patch509/Patch516/g" kernel.spec

### Create patch file with custom drivers
echo >&2 "===]> Info: Creating patch file... ";
FEDORA_KERNEL_VERSION=${FEDORA_KERNEL_VERSION} ../patch_driver.sh

### Apply patches
if [ ! -f scripts/newpatch.sh ]; then
  cp -rf ../fedora/newpatch.sh scripts/newpatch.sh
fi
echo >&2 "===]> Info: Applying patches... ";
[ ! -d ../patches ] && { echo 'Patches directory not found!'; exit 1; }
while IFS= read -r file
do
  echo "adding $file"
  scripts/newpatch.sh "$file"
done < <(find ../patches -type f -name "*.patch" | sort)

### Change buildid to mbp
echo >&2 "===]> Info: Setting kernel name... ";
sed -i 's/%define buildid.*/%define buildid .mbp/' ./kernel.spec

### Build src rpm
echo >&2 "===]> Info: Bulding src.rpm ... ";
fedpkg --release $FEDORA_KERNEL_BRANCH_NAME srpm

### Build non-debug rpms
echo >&2 "===]> Info: Bulding kernel ... ";
./scripts/fast-build.sh x86_64 "$(find . -type f -name "*.src.rpm")"
rpmbuild_exitcode=$?

### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying rpms and calculating SHA256 ... ";
cp -rfv /root/rpmbuild/RPMS/x86_64/*.rpm /tmp/artifacts/
sha256sum /root/rpmbuild/RPMS/x86_64/*.rpm > /tmp/artifacts/sha256

### Add patches to artifacts
cd ..
zip -r patches.zip patches/
cp -rfv patches.zip /tmp/artifacts/

exit $rpmbuild_exitcode
