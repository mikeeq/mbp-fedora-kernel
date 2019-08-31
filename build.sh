#!/bin/sh

FEDORA_KERNEL_BRANCH_NAME=f30
FEDORA_KERNEL_COMMIT_HASH=206ff7fd1400a2c1764aeac4895dbce5d382077a      # Linux v5.2.11 - https://src.fedoraproject.org/rpms/kernel/commits/f30

### Debug commands
echo "FEDORA_KERNEL_BRANCH_NAME=$FEDORA_KERNEL_BRANCH_NAME"
echo "FEDORA_KERNEL_COMMIT_HASH=$FEDORA_KERNEL_COMMIT_HASH"
pwd
ls
echo "CPU threads: $(nproc --all)"
cat /proc/cpuinfo | grep 'model name' | uniq
# git clone --depth 1 --single-branch --branch v5.1.19 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

### Dependencies
dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools

### Clone Fedora Kernel git repo
git clone --single-branch --branch $FEDORA_KERNEL_BRANCH_NAME https://src.fedoraproject.org/rpms/kernel.git
cd kernel
## Cleanup
rm -rfv *.rpm
rm -rf ~/rpmbuild/*
git reset --hard $FEDORA_KERNEL_BRANCH_NAME
git checkout $FEDORA_KERNEL_BRANCH_NAME
git branch -d fedora_patch_src
fedpkg clean
## Change branch
git checkout $FEDORA_KERNEL_COMMIT_HASH
git reset --hard $FEDORA_KERNEL_COMMIT_HASH
git checkout -b fedora_patch_src
dnf -y builddep kernel.spec

### Apply patches
for patch_file in $(ls ../patches)
do
  scripts/newpatch.sh ../patches/$patch_file
done

### Build src rpm
fedpkg --release $FEDORA_KERNEL_BRANCH_NAME srpm

### Build non-debug rpms
./scripts/fast-build.sh x86_64 $(ls | grep src.rpm)
rpmbuild_exitcode=$?

### Copy artifacts to shared volume
find ~/rpmbuild/ | grep '\.rpm'
cp -rfv ~/rpmbuild/RPMS/x86_64/*.rpm /tmp/artifacts/

exit $rpmbuild_exitcode
