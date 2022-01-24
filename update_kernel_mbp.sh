#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
KERNEL_PATCH_PATH=/tmp/kernel_patch

UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-v5.15-f35}
MBP_FEDORA_BRANCH=f35
BCE_DRIVER_GIT_URL=https://github.com/t2linux/apple-bce-drv
BCE_DRIVER_BRANCH_NAME=aur
BCE_DRIVER_COMMIT_HASH=f93c6566f98b3c95677de8010f7445fa19f75091
APPLE_IB_DRIVER_GIT_URL=https://github.com/Redecorating/apple-ib-drv
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=467df9b11cb55456f0365f40dd11c9e666623bf3

if [ "$EUID" -ne 0 ]; then
  echo >&2 "===]> Please run as root --> sudo -i; update_kernel_mbp"
  exit
fi

rm -rf ${KERNEL_PATCH_PATH}
mkdir -p ${KERNEL_PATCH_PATH}
cd ${KERNEL_PATCH_PATH} || exit

### Downloading update_kernel_mbp script
echo >&2 "===]> Info: Downloading update_kernel_mbp ${UPDATE_SCRIPT_BRANCH} script... ";
rm -rf /usr/local/bin/update_kernel_mbp
if [ -f /usr/bin/update_kernel_mbp ]; then
  cp -rf /usr/bin/update_kernel_mbp ${KERNEL_PATCH_PATH}/
  ORG_SCRIPT_SHA=$(sha256sum ${KERNEL_PATCH_PATH}/update_kernel_mbp | awk '{print $1}')
fi
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/"${UPDATE_SCRIPT_BRANCH}"/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp
if [ -f /usr/bin/update_kernel_mbp ]; then
  NEW_SCRIPT_SHA=$(sha256sum /usr/bin/update_kernel_mbp | awk '{print $1}')
  if [[ "$ORG_SCRIPT_SHA" != "$NEW_SCRIPT_SHA" ]]; then
    echo >&2 "===]> Info: update_kernel_mbp script was updated please rerun!" && exit
  else
    echo >&2 "===]> Info: update_kernel_mbp script is in the latest version proceeding..."
  fi
else
   echo >&2 "===]> Info: update_kernel_mbp script was installed..."
fi

### Download kernel packages
KERNEL_PACKAGES=()

CURRENT_KERNEL_VERSION=$(uname -r)
echo >&2 "===]> Info: Current kernel version: ${CURRENT_KERNEL_VERSION}";

if [[ -n "${KERNEL_VERSION:-}" ]]; then
  MBP_KERNEL_TAG=${KERNEL_VERSION}
  echo >&2 "===]> Info: Downloading specified kernel: ${MBP_KERNEL_TAG}";
else
  MBP_VERSION=mbp
  MBP_KERNEL_TAG=$(curl -Ls https://github.com/mikeeq/mbp-fedora-kernel/releases/ | grep rpm | grep download | grep "${MBP_VERSION}" | cut -d'/' -f6 | head -n1 | cut -d'v' -f2)
  echo >&2 "===]> Info: Downloading latest ${MBP_VERSION} kernel: ${MBP_KERNEL_TAG}";
fi

while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL https://github.com/mikeeq/mbp-fedora-kernel/releases/tag/v"${MBP_KERNEL_TAG}" | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1)

KERNEL_PACKAGE_NAME=${KERNEL_PACKAGES[0]}
TEMPVAR=${KERNEL_PACKAGE_NAME//kernel-}
KERNEL_FULL_VERSION=${TEMPVAR//.rpm}

for i in "${KERNEL_PACKAGES[@]}"; do
  curl -LO  https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v"${MBP_KERNEL_TAG}"/"${i}"
done

echo >&2 "===]> Info: Installing dependencies...";
dnf install -y bison elfutils-libelf-devel flex gcc openssl-devel

echo >&2 "===]> Info: Installing kernel version: ${MBP_KERNEL_TAG}";
rpm --force -i ./*.rpm

### Install custom drivers
## BCE - Apple T2
echo >&2 "===]> Info: Downloading BCE driver... ";
git clone --depth 1 --single-branch --branch "${BCE_DRIVER_BRANCH_NAME}" "${BCE_DRIVER_GIT_URL}" ./bce
cd bce || exit
git checkout "${BCE_DRIVER_COMMIT_HASH}"

make -C /lib/modules/"${KERNEL_FULL_VERSION}"/build/ M="$(pwd)" modules
cp -rfv ./*.ko /lib/modules/"${KERNEL_FULL_VERSION}"/extra
cd ..

## Touchbar
echo >&2 "===]> Info: Downloading Touchbar driver... ";
git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} ./touchbar
cd touchbar || exit
git checkout ${APPLE_IB_DRIVER_COMMIT_HASH}

make -C /lib/modules/"${KERNEL_FULL_VERSION}"/build/ M="$(pwd)" modules
cp -rfv ./*.ko /lib/modules/"${KERNEL_FULL_VERSION}"/extra

### Add custom drivers to be loaded at boot
echo >&2 "===]> Info: Setting up GRUB to load custom drivers at boot... ";
rm -rf /etc/modules-load.d/bce.conf
echo -e 'hid-apple\nbcm5974\nsnd-seq\napple_bce\napple_ibridge\napple_ib_tb' > /etc/modules-load.d/apple_bce.conf
echo -e 'add_drivers+=" hid_apple snd-seq apple_bce "\nforce_drivers+=" hid_apple snd-seq apple_bce "' > /etc/dracut.conf

sed -i '/^GRUB_ENABLE_BLSCFG=true/c\GRUB_ENABLE_BLSCFG=false' /etc/default/grub

echo >&2 "===]> Info: Rebuilding initramfs with custom drivers... ";
depmod -a "${KERNEL_FULL_VERSION}"
dracut -f /boot/initramfs-"${KERNEL_FULL_VERSION}".img "${KERNEL_FULL_VERSION}"

### Suspend fix
echo >&2 "===]> Info: Adding suspend fix... ";
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora/${MBP_FEDORA_BRANCH}/files/suspend/rmmod_tb.sh -o /lib/systemd/system-sleep/rmmod_tb.sh
chmod +x /lib/systemd/system-sleep/rmmod_tb.sh

### Grub
echo >&2 "===]> Info: Rebuilding GRUB config... ";
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora/${MBP_FEDORA_BRANCH}/files/grub/30_os-prober -o /etc/grub.d/30_os-prober
chmod 755 /etc/grub.d/30_os-prober
grub2-mkconfig -o /boot/grub2/grub.cfg

### Cleanup
echo >&2 "===]> Info: Cleaning old kernel pkgs (leaving 3 latest versions)... ";
rm -rf ${KERNEL_PATCH_PATH}
dnf autoremove -y
dnf remove -y "$(dnf repoquery --installonly --latest-limit=-3 -q)"

echo >&2 "===]> Info: Kernel update to ${MBP_KERNEL_TAG} finished successfully! ";
