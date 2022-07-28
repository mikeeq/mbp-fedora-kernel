#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
KERNEL_PATCH_PATH=/tmp/kernel_patch

UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-v5.18-f36}
MBP_FEDORA_BRANCH=f36

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
curl -L "https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/update_kernel_mbp.sh" -o /usr/bin/update_kernel_mbp
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

while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL "https://github.com/mikeeq/mbp-fedora-kernel/releases/tag/v${MBP_KERNEL_TAG}" | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1)

for i in "${KERNEL_PACKAGES[@]}"; do
  curl -LO "https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${MBP_KERNEL_TAG}/${i}"
done

### Add custom drivers to be loaded at boot
echo >&2 "===]> Info: Setting up GRUB to load custom drivers at boot... ";
rm -rf /etc/modules-load.d/bce.conf
echo -e 'hid-apple\nbcm5974\nsnd-seq\napple_bce' > /etc/modules-load.d/apple_bce.conf
echo -e 'add_drivers+=" hid_apple snd-seq apple_bce "\nforce_drivers+=" hid_apple snd-seq apple_bce "' > /etc/dracut.conf

GRUB_CMDLINE_VALUE=$(grep -v '#' /etc/default/grub | grep -w GRUB_CMDLINE_LINUX | cut -d'"' -f2)

for i in efi=noruntime pcie_ports=compat; do
  if ! echo "$GRUB_CMDLINE_VALUE" | grep -w $i; then
   GRUB_CMDLINE_VALUE="$GRUB_CMDLINE_VALUE $i"
  fi
done

sed -i "s:^GRUB_CMDLINE_LINUX=.*:GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_VALUE}\":g" /etc/default/grub
sed -i '/^GRUB_ENABLE_BLSCFG=true/c\GRUB_ENABLE_BLSCFG=false' /etc/default/grub

echo >&2 "===]> Info: Adding fedora-mbp yum repo gpg key...";
curl -sSL "https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/yum-repo/fedora-mbp.gpg" > ./fedora-mbp.gpg
rpm --import ./fedora-mbp.gpg
rm -rfv ./fedora-mbp.gpg

echo >&2 "===]> Info: Installing kernel version: ${MBP_KERNEL_TAG}";
rpm --force -i ./*.rpm

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
# shellcheck disable=SC2046
dnf remove -y $(dnf repoquery --installonly --latest-limit=-3 -q)

echo >&2 "===]> Info: Kernel update to ${MBP_KERNEL_TAG} finished successfully! ";
