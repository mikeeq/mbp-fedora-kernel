#!/bin/sh

FEDORA_KERNEL_BRANCH_NAME=f30
FEDORA_KERNEL_COMMIT_HASH=7d82fa8c6f583af671891653d143d2e826723fb2      # Linux v5.1.19 - https://src.fedoraproject.org/rpms/kernel/commits/f30

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
git reset --hard $FEDORA_KERNEL_BRANCH_NAME
git checkout $FEDORA_KERNEL_BRANCH_NAME
git branch -d fedora_patch_src
fedpkg clean
## Change branch
git checkout $FEDORA_KERNEL_COMMIT_HASH
git reset --hard $FEDORA_KERNEL_COMMIT_HASH
git checkout -b fedora_patch_src
dnf -y builddep kernel.spec

##### v5.2.8 patches from aunali1 repo
# cd ..
# git clone https://github.com/aunali1/linux-mbp-arch
# cd kernel
### Fix for 5.2.8
# sed -i "s/Patch526/Patch536/g" kernel.spec
# sed -i "s/Patch527/Patch537/g" kernel.spec

### Fix subject header in patch files, subject header cannot be longer than 64 chars
# sed -i "/.*Subject: .*/c Subject: [PATCH 4/4] nvme-pci: Support apple t2" ../linux-mbp-arch/2004-nvme-pci-Support-shared-tags-across-queues-for-Apple.patch
# for patch_file in $(ls ../linux-mbp-arch | grep patch | grep -v 00)
# do
#   sed -i "1 i\From: fedora kernel <fedora@kernel.org>\nSubject: patch $patch_file" ../linux-mbp-arch/$patch_file
# done
# for patch_file in $(ls ../linux-mbp-arch | grep patch | grep -v 000)
# do
#   scripts/newpatch.sh ../linux-mbp-arch/$patch_file
# done
#####

for patch_file in $(ls ../patches)
do
  scripts/newpatch.sh ../patches/$patch_file
done

### Build src rpm
fedpkg --release $FEDORA_KERNEL_BRANCH_NAME srpm

### Build non-debug rpms
rpmbuild --target x86_64 --with headers --without debug --without debuginfo --without perf --without tools --rebuild $(ls | grep src.rpm)
rpmbuild_exitcode=$?

### Copy artifacts to shared volume
cp -rfv /root/rpmbuild/RPMS/x86_64/*.rpm /tmp/artifacts/

exit $rpmbuild_exitcode
