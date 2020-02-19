#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
KERNEL_PATCH_PATH=/tmp/kernel_patch

BCE_DRIVER_GIT_URL=https://github.com/MCMrARM/mbp2018-bridge-drv.git
BCE_DRIVER_BRANCH_NAME=master
BCE_DRIVER_COMMIT_HASH=b43fcc069da73e051072fde24af4014c9c487286
APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871

if [ "$EUID" -ne 0 ]
  then echo "Please run as root --> sudo -i; update_kernel_mbp"
  exit
fi

rm -rf ${KERNEL_PATCH_PATH}
mkdir -p ${KERNEL_PATCH_PATH}
cd ${KERNEL_PATCH_PATH} || exit

### Update update_kernel_mbp script
echo >&2 "===]> Info: Updating update_kernel_mbp script... ";
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/v5.4-f31/update_kernel_mbp.sh -o /usr/local/bin/update_kernel_mbp
chmod +x /usr/local/bin/update_kernel_mbp

### Download latest kernel
echo >&2 "===]> Info: Downloading latest kernel... ";
KERNEL_PACKAGE_NAME=$(curl -sL https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1 | head -n1)
KERNEL_VERSION=$(echo "${KERNEL_PACKAGE_NAME}" | cut -d'-' -f2)
OS_VERSION=$(echo "${KERNEL_PACKAGE_NAME}" | cut -d'.' -f5 | cut -d'c' -f2)
TEMPVAR=${KERNEL_PACKAGE_NAME//kernel-}
KERNEL_FULL_VERSION=${TEMPVAR//.rpm}

echo >&2 "===]> Info: Latest kernel version: ${KERNEL_VERSION} ";
for i in $(curl -sL https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1); do
  curl -LO  https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v"${KERNEL_VERSION}"-f"${OS_VERSION}"/"${i}"
done

dnf install -y ./*.rpm

### Install custom drivers
## BCE - Apple T2
echo >&2 "===]> Info: Downloading BCE driver... ";
git clone --depth 1 --single-branch --branch "${BCE_DRIVER_BRANCH_NAME}" "${BCE_DRIVER_GIT_URL}" ./bce
cd bce || exit
git checkout "${BCE_DRIVER_COMMIT_HASH}"

make -C /lib/modules/"${KERNEL_FULL_VERSION}"/build/ M="$(pwd)" modules
cp -rfv ./bce.ko /lib/modules/"${KERNEL_FULL_VERSION}"/extra
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
echo -e 'hid-apple\nbcm5974\nsnd-seq\nbce\napple_ibridge\napple_ib_tb' > /etc/modules-load.d/bce.conf
echo -e 'blacklist thunderbolt' > /etc/modprobe.d/blacklist.conf
echo -e 'add_drivers+="hid_apple snd-seq bce"\nforce_drivers+="hid_apple snd-seq bce"' > /etc/dracut.conf

GRUB_CMDLINE_VALUE=$(grep -v '#' /etc/default/grub | grep -w GRUB_CMDLINE_LINUX | cut -d'"' -f2)

for i in efi=noruntime pcie_ports=compat modprobe.blacklist=thunderbolt; do
  if ! echo "$GRUB_CMDLINE_VALUE" | grep -w $i; then
   GRUB_CMDLINE_VALUE="$GRUB_CMDLINE_VALUE $i"
  fi
done

sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_VALUE}\"/g" /etc/default/grub

echo >&2 "===]> Info: Rebuilding initramfs with custom drivers... ";
depmod -a "${KERNEL_FULL_VERSION}"
dracut -f /boot/initramfs-"${KERNEL_FULL_VERSION}".img "${KERNEL_FULL_VERSION}"

### Cleanup
rm -rf ${KERNEL_PATCH_PATH}
