#!/bin/bash

set -eu -o pipefail

## Update fedora docker image tag, because kernel build is using `uname -r` when defining package version variable
RPMBUILD_PATH=/root/rpmbuild
MBP_VERSION=mbp
FEDORA_KERNEL_VERSION=5.18.6-200.fc36      # https://bodhi.fedoraproject.org/updates/?search=&packages=kernel&releases=F36
REPO_PWD=$(pwd)

### Debug commands
echo "FEDORA_KERNEL_VERSION=$FEDORA_KERNEL_VERSION"

pwd
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

### Dependencies
dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools zip curl dwarves libbpf

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

### Apply patches
echo >&2 "===]> Info: Applying patches...";
mkdir -p "${REPO_PWD}"/patches
while IFS= read -r file
do
  echo >&2 "===]> Info: Applying patch: $file"
  "${REPO_PWD}"/patch_kernel.sh "$file"
done < <(find "${REPO_PWD}"/patches -type f -name "*.patch" | sort)

# echo >&2 "===]> Info: Applying kconfig changes... ";
# echo "CONFIG_APPLE_BCE=m" >> "${RPMBUILD_PATH}/SOURCES/kernel-local"
# echo "CONFIG_APPLE_IBRIDGE=m" >> "${RPMBUILD_PATH}/SOURCES/kernel-local"

### Change buildid to mbp
echo >&2 "===]> Info: Setting kernel name...";
sed -i "s/# define buildid.*/%define buildid .${MBP_VERSION}/" "${RPMBUILD_PATH}"/SPECS/kernel.spec

### Build non-debug rpms
echo >&2 "===]> Info: Bulding kernel ...";
cd "${RPMBUILD_PATH}"/SPECS
rpmbuild -bb --without debug --without debuginfo --without perf --without tools --target=x86_64 kernel.spec
rpmbuild_exitcode=$?

### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying rpms and calculating SHA256 ...";
cd "${REPO_PWD}"
mkdir -p ./output_zip
cp -rfv ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm ./output_zip/
sha256sum ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm > ./output_zip/sha256

### Add patches to artifacts
zip -r patches.zip patches/
cp -rfv patches.zip ./output_zip/
du -h ./output_zip/

exit $rpmbuild_exitcode
