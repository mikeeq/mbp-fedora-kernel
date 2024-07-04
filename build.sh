#!/bin/bash

set -eu -o pipefail

[[ $(df -k --output=avail / | tail -1) -gt 19777111 ]] || (echo "Free disk space is < 20 GB, build will fail, are you sure ?" && sleep 15)

## Update fedora docker image tag, because kernel build is using `uname -r` when defining package version variable
RPMBUILD_PATH=/root/rpmbuild
MBP_VERSION=mbp
FEDORA_KERNEL_VERSION=6.9.7-200.fc40      # https://bodhi.fedoraproject.org/updates/?search=&packages=kernel&releases=f40
REPO_PWD=$(pwd)

### Debug commands
echo "FEDORA_KERNEL_VERSION=$FEDORA_KERNEL_VERSION"

pwd
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

### Dependencies
dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools zip curl dwarves libbpf rpm-sign

rm -rf ${RPMBUILD_PATH}/SOURCES
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
FEDORA_KERNEL_VERSION=${FEDORA_KERNEL_VERSION} "${REPO_PWD}"/kernel_patches.sh

### Apply patches
echo >&2 "===]> Info: Applying patches...";
mkdir -p "${REPO_PWD}"/patches
while IFS= read -r file
do
  echo >&2 "===]> Info: Applying patch: $file"
  "${REPO_PWD}"/patch_kernel_spec.sh "$file"
done < <(find "${REPO_PWD}"/patches -type f -name "*.patch" | sort)

echo >&2 "===]> Info: Applying kconfig changes... ";
{
  echo "CONFIG_APPLE_BCE=m"
  echo "CONFIG_APPLE_GMUX=m"
  echo "CONFIG_BRCMFMAC=m"
  echo "CONFIG_BT_BCM=m"
  echo "CONFIG_BT_HCIBCM4377=m"
  echo "CONFIG_BT_HCIUART_BCM=y"
  echo "CONFIG_BT_HCIUART=m"
  echo "CONFIG_HID_APPLETB_BL=m"
  echo "CONFIG_HID_APPLETB_KBD=m"
  echo "CONFIG_HID_APPLE=m"
  echo "CONFIG_DRM_APPLETBDRM=m"
  echo "CONFIG_DRM_KUNIT_TEST=m"
  echo "CONFIG_HID_APPLE_MAGIC_BACKLIGHT=m"
  echo "CONFIG_HID_SENSOR_ALS=m"
  echo "CONFIG_SND_PCM=m"
  echo "CONFIG_STAGING=y"
  echo "CONFIG_APFS_FS=m"

} >> "${RPMBUILD_PATH}/SOURCES/kernel-local"

### Change buildid to mbp
echo >&2 "===]> Info: Setting kernel name...";
sed -i "s/# define buildid.*/%define buildid .${MBP_VERSION}/" "${RPMBUILD_PATH}"/SPECS/kernel.spec

### Remove all non-x86_64 kernel config files to fix CONFIG_BT_HCIBCM4377
echo >&2 "===]> Info: Removing non-x86_64 config files...";
find /root/rpmbuild/SOURCES -type f | grep "config$" | grep kernel | grep -v x86_64 | while IFS='' read -r line
do
  rm -rfv "$line"
done

### Disable process-configs.sh from running in kernel.spec (it fails for CONFIG_BT_HCIBCM4377)
# echo >&2 "===]> Info: Disable process_configs.sh...";
# sed -i '/RHJOBS=$RPM_BUILD_NCPUS PACKAGE_NAME=kernel \.\/process_configs.sh $OPTS ${specversion}/d' "${RPMBUILD_PATH}"/SPECS/kernel.spec

### Build non-debug kernel rpms
echo >&2 "===]> Info: Bulding kernel ...";
cd "${RPMBUILD_PATH}"/SPECS
rpmbuild -bb --with baseonly --without debug --without debuginfo --target=x86_64 kernel.spec
kernel_rpmbuild_exitcode=$?
echo >&2 "===]> Info: kernel_rpmbuild_exitcode=$kernel_rpmbuild_exitcode"

echo >&2 "===]> Info: Copy source files for other RPMs ...";
cp -rfv "${REPO_PWD}"/yum-repo/sources/* ${RPMBUILD_PATH}/SOURCES/

### Build non-debug mbp-fedora-t2-config rpm
echo >&2 "===]> Info: Bulding non-debug mbp-fedora-t2-config RPM ...";
cp -rfv "${REPO_PWD}"/yum-repo/specs/mbp-fedora-t2-config.spec ./
rpmbuild -bb --without debug --without debuginfo --target=x86_64 mbp-fedora-t2-config.spec
config_rpmbuild_exitcode=$?
echo >&2 "===]> Info: mbp-fedora-t2-config config_rpmbuild_exitcode=$config_rpmbuild_exitcode"

### Build non-debug mbp-fedora-t2-repo rpm
echo >&2 "===]> Info: Bulding non-debug mbp-fedora-t2-repo RPM ...";
cp -rfv "${REPO_PWD}"/yum-repo/specs/mbp-fedora-t2-repo.spec ./
rpmbuild -bb --without debug --without debuginfo --target=x86_64 mbp-fedora-t2-repo.spec
repo_rpmbuild_exitcode=$?
echo >&2 "===]> Info: mbp-fedora-t2-repo repo_rpmbuild_exitcode=$repo_rpmbuild_exitcode"

### Import rpm siging key
echo >&2 "===]> Info: Importing RPM signing key ..."
cat <<EOT >> ~/.rpmmacros
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name mbp-fedora
%_gpgbin /usr/bin/gpg
EOT

echo "$RPM_SIGNING_KEY" | base64 -d > ./rpm_signing_key
gpg --import ./rpm_signing_key
rpm --import "${REPO_PWD}"/yum-repo/sources/repo/mbp-fedora-repo.gpg
rm -rfv ./rpm_signing_key

rpm --addsign ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm

### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying rpms and calculating SHA256 ...";
cd "${REPO_PWD}"
mkdir -p ./output_zip
cp -rfv ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm ./output_zip/
sha256sum ${RPMBUILD_PATH}/RPMS/x86_64/*.rpm > ./output_zip/sha256

### Copy other artifacts
cp -rfv "${RPMBUILD_PATH}/SOURCES/kernel-local" patches/
cp -rfv "${RPMBUILD_PATH}/SPECS/kernel.spec" patches/

### Add patches to artifacts
zip -r patches.zip patches/
cp -rfv patches.zip ./output_zip/
echo
du -sh ./output_zip
echo
du -sh ./output_zip/*.rpm

exit $kernel_rpmbuild_exitcode
