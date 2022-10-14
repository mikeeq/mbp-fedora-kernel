#!/bin/bash

set -eu -o pipefail

[[ $(df -k --output=avail / | tail -1) -gt 19777111 ]] || echo "Free disk space is < 20 GB, build will fail, are you sure ?" && sleep 15

## Update fedora docker image tag, because kernel build is using `uname -r` when defining package version variable
RPMBUILD_PATH=/root/rpmbuild
MBP_VERSION=mbp
#FEDORA_KERNEL_VERSION=5.19.1-300.fc36      # https://bodhi.fedoraproject.org/updates/?search=&packages=kernel&releases=F36
FEDORA_KERNEL_VERSION=5.19.15-200.fc36
REPO_PWD=$(pwd)

### Debug commands
echo "FEDORA_KERNEL_VERSION=$FEDORA_KERNEL_VERSION"

pwd
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

### Dependencies
dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools zip curl dwarves libbpf rpm-sign

## Set home build directory
rpmdev-setuptree

## Install the kernel source and finish installing dependencies
cd ${RPMBUILD_PATH}/SOURCES
koji download-build --arch=src kernel-${FEDORA_KERNEL_VERSION}
rpm -Uvh kernel-${FEDORA_KERNEL_VERSION}.src.rpm

cd ${RPMBUILD_PATH}/SPECS
dnf -y builddep kernel.spec

### Create patch file with custom drivers
echo >&2 "===]> Info: Creating patch file...";
FEDORA_KERNEL_VERSION=${FEDORA_KERNEL_VERSION} "${REPO_PWD}"/patch_driver.sh

echo >&2 "===]> Info: Overwriting few patches with to be kernel 5.19 compatible, TO BE REVIEWED...";
cp -f /repo/*patch /repo/patches
rm -f /repo/patches/5001-Fix-for-touchbar.patch  # TODO ? really ? whole patchfile ?

### Apply patches
echo >&2 "===]> Info: Applying patches...";
mkdir -p "${REPO_PWD}"/patches
while IFS= read -r file
do
  echo >&2 "===]> Info: Applying patch: $file"
  "${REPO_PWD}"/patch_kernel.sh "$file"
done < <(find "${REPO_PWD}"/patches -type f -name "*.patch" | sort)

echo >&2 "===]> Info: Applying kconfig changes... ";
echo "CONFIG_APPLE_BCE=m" >> "${RPMBUILD_PATH}/SOURCES/kernel-local"
echo "CONFIG_APPLE_IBRIDGE=m" >> "${RPMBUILD_PATH}/SOURCES/kernel-local"
# echo "CONFIG_BT_HCIBCM4377=m" >> "${RPMBUILD_PATH}/SOURCES/kernel-local"

### Change buildid to mbp
echo >&2 "===]> Info: Setting kernel name...";
sed -i "s/# define buildid.*/%define buildid .${MBP_VERSION}/" "${RPMBUILD_PATH}"/SPECS/kernel.spec

### Build non-debug kernel rpms
echo >&2 "===]> Info: Bulding kernel ...";
cd "${RPMBUILD_PATH}"/SPECS
rpmbuild -bb --with baseonly --without debug --without debuginfo --target=x86_64 kernel.spec
rpmbuild_exitcode=$?

### Build non-debug mbp-fedora-t2-config rpms
cp -rfv "${REPO_PWD}"/yum-repo/mbp-fedora-t2-config/rpm.spec ./
cp -rfv "${REPO_PWD}"/yum-repo/mbp-fedora-t2-config/suspend/rmmod_tb.sh ${RPMBUILD_PATH}/SOURCES
find .
pwd
rpmbuild -bb --without debug --without debuginfo --target=x86_64 rpm.spec

### Import rpm siging keys
cat <<EOT >> ~/.rpmmacros
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name mbp-fedora
%_gpgbin /usr/bin/gpg
EOT

echo "$RPM_SIGNING_KEY" | base64 -d > ./rpm_signing_key
gpg --import ./rpm_signing_key
rpm --import "${REPO_PWD}"/yum-repo/fedora-mbp.gpg
rm -rfv ./rpm_signing_key

rpm --addsign ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm

### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying rpms and calculating SHA256 ...";
cd "${REPO_PWD}"
mkdir -p ./output_zip
cp -rfv ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm ./output_zip/
sha256sum ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm > ./output_zip/sha256

### Add patches to artifacts
zip -r patches.zip patches/
cp -rfv patches.zip ./output_zip/
echo
du -sh ./output_zip
echo
du -sh ./output_zip/*.rpm

exit $rpmbuild_exitcode
