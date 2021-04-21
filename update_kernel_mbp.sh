#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
KERNEL_PATCH_PATH=/tmp/kernel_patch

UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-v5.10-f33}
MBP_FEDORA_BRANCH=f33
BCE_DRIVER_GIT_URL=https://github.com/t2linux/apple-bce-drv
BCE_DRIVER_BRANCH_NAME=aur
BCE_DRIVER_COMMIT_HASH=c884d9ca731f2118a58c28bb78202a0007935998
APPLE_IB_DRIVER_GIT_URL=https://github.com/t2linux/apple-ib-drv
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=fc9aefa5a564e6f2f2bb0326bffb0cef0446dc05    # https://github.com/roadrunner2/macbook12-spi-driver/commits/mbp15

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

### Download latest kernel
KERNEL_PACKAGES=()
if [[ ${1-} == "--rc" ]]; then
  MBP_KERNEL_TAG=$(curl -sL https://github.com/mikeeq/mbp-fedora-kernel/releases/ | grep rpm | grep 'rc' | head -n 1 | cut -d'v' -f2 | cut -d'/' -f1)
  echo >&2 "===]> Info: Downloading latest RC kernel: ${MBP_KERNEL_TAG}";
  while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL https://github.com/mikeeq/mbp-fedora-kernel/releases/tag/v"${MBP_KERNEL_TAG} "| grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1)
else
  MBP_KERNEL_TAG=$(curl -s https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | cut -d'v' -f2 | cut -d'"' -f1)
  echo >&2 "===]> Info: Downloading latest stable kernel: ${MBP_KERNEL_TAG}";
  while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1)
fi

KERNEL_PACKAGE_NAME=${KERNEL_PACKAGES[0]}
TEMPVAR=${KERNEL_PACKAGE_NAME//kernel-}
KERNEL_FULL_VERSION=${TEMPVAR//.rpm}

for i in "${KERNEL_PACKAGES[@]}"; do
  curl -LO  https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v"${MBP_KERNEL_TAG}"/"${i}"
done

echo >&2 "===]> Info: Installing kernel version: ${MBP_KERNEL_TAG}";
rpm --force -i ./*.rpm

[ -x "$(command -v gcc)" ] || dnf install -y gcc

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
echo -e 'add_drivers+=" hid_apple snd-seq bce "\nforce_drivers+=" hid_apple snd-seq bce "' > /etc/dracut.conf

GRUB_CMDLINE_VALUE=$(grep -v '#' /etc/default/grub | grep -w GRUB_CMDLINE_LINUX | cut -d'"' -f2)

for i in efi=noruntime pcie_ports=compat modprobe.blacklist=thunderbolt; do
  if ! echo "$GRUB_CMDLINE_VALUE" | grep -w $i; then
   GRUB_CMDLINE_VALUE="$GRUB_CMDLINE_VALUE $i"
  fi
done

sed -i "s:^GRUB_CMDLINE_LINUX=.*:GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_VALUE}\":g" /etc/default/grub

echo >&2 "===]> Info: Rebuilding initramfs with custom drivers... ";
depmod -a "${KERNEL_FULL_VERSION}"
dracut -f /boot/initramfs-"${KERNEL_FULL_VERSION}".img "${KERNEL_FULL_VERSION}"

### Grub
echo >&2 "===]> Info: Rebuilding GRUB config... ";
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora/${MBP_FEDORA_BRANCH}/files/grub/30_os-prober -o /etc/grub.d/30_os-prober
chmod 755 /etc/grub.d/30_os-prober
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

### Cleanup
echo >&2 "===]> Info: Cleaning old kernel pkgs (leaving 3 latest versions)... ";
rm -rf ${KERNEL_PATCH_PATH}
dnf autoremove -y
dnf remove -y "$(dnf repoquery --installonly --latest-limit=-3 -q)"
