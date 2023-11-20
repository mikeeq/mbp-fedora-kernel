#!/bin/bash

set -eu -o pipefail

KERNEL_PATCH_PATH=/tmp/kernel_patch

UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-v6.5-f39}
MBP_FEDORA_BRANCH=f39

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

URL_UPDATE_SCRIPT="https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/update_kernel_mbp.sh"

install_update_kernel_mbp () {
  curl -L "$URL_UPDATE_SCRIPT" -o /usr/bin/update_kernel_mbp
  chmod +x /usr/bin/update_kernel_mbp
}

if curl -sf -LI "$URL_UPDATE_SCRIPT" 1>/dev/null; then
  if [ -f /usr/bin/update_kernel_mbp ]; then
    install_update_kernel_mbp
    NEW_SCRIPT_SHA=$(sha256sum /usr/bin/update_kernel_mbp | awk '{print $1}')
    if [[ "$ORG_SCRIPT_SHA" != "$NEW_SCRIPT_SHA" ]]; then
      echo >&2 "===]> Exit: update_kernel_mbp script was updated please rerun!" && exit
    else
      echo >&2 "===]> Info: update_kernel_mbp script is in the latest version proceeding..."
    fi
  else
    install_update_kernel_mbp
    echo >&2 "===]> Info: update_kernel_mbp script was installed..."
  fi
else
  echo >&2 "===]> Exit: Wrong UPDATE_SCRIPT_BRANCH variable, or update_kernel_mbp.sh doesn't exist on default branch - please rerun!" && exit
fi

### Copy grub config without finding macos partition to fix failure reading sector error
echo >&2 "===]> Info: Downloading a fix for GRUB os prober... ";
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora/${MBP_FEDORA_BRANCH}/files/grub/30_os-prober -o /etc/grub.d/30_os-prober
chmod 755 /etc/grub.d/30_os-prober

### Download kernel packages
KERNEL_PACKAGES=()

CURRENT_KERNEL_VERSION=$(uname -r)
echo >&2 "===]> Info: Current kernel version: ${CURRENT_KERNEL_VERSION}";

if [[ -n "${KERNEL_VERSION:-}" ]]; then
  MBP_KERNEL_TAG=${KERNEL_VERSION}
  echo >&2 "===]> Info: Using specified kernel version: ${MBP_KERNEL_TAG}";
else
  ### Check yum repo
  if dnf repolist | grep -iq mbp-fedora; then
    echo >&2 "===]> Info: mbp-fedora repo was already added, skipping..."
  else
    echo >&2 "===]> Info: mbp-fedora repo not found, installing latest RPMs...";
    INSTALL_LATEST=true
  fi
  MBP_KERNEL_TAG=$(curl -sI https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | grep -i "location:" | cut -d'v' -f2 | tr -d '\r')
  echo >&2 "===]> Info: Using latest kernel version: ${MBP_KERNEL_TAG}";
fi

if [[ -n "${KERNEL_VERSION:-}" ]] || [ "${INSTALL_LATEST:-false}" = true ] || [ "${1:-}" == "--github" ]; then
  echo >&2 "===]> Info: Downloading kernel RPMs: ${MBP_KERNEL_TAG}";

  while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL "https://github.com/mikeeq/mbp-fedora-kernel/releases/expanded_assets/v${MBP_KERNEL_TAG}" | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1)

  for i in "${KERNEL_PACKAGES[@]}"; do
    curl -LO "https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${MBP_KERNEL_TAG}/${i}"
  done

  ### Check yum repo gpg key if exists
  if rpm -q gpg-pubkey --qf '%{SUMMARY}\n' | grep -q -i mbp-fedora; then
    echo >&2 "===]> Info: mbp-fedora yum repo gpg key is already added, skipping...";
  else
    echo >&2 "===]> Info: Adding mbp-fedora yum repo gpg key...";
    curl -sSL "https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/yum-repo/sources/repo/mbp-fedora-repo.gpg" > ./mbp-fedora.gpg
    rpm --import ./mbp-fedora.gpg
    rm -rf ./mbp-fedora.gpg
  fi

  echo >&2 "===]> Info: Installing dependencies...";
  dnf install -y gcc openssl-devel flex elfutils bison elfutils-libelf-devel

  echo >&2 "===]> Info: Installing kernel version: ${MBP_KERNEL_TAG}";
  rpm --force -i ./*.rpm
else
  echo >&2 "===]> Info: Installing latest kernel from repo...";
  dnf update -y kernel kernel-core kernel-modules mbp-fedora-t2-config mbp-fedora-t2-repo
fi

### Cleanup
echo >&2 "===]> Info: Cleaning old kernel pkgs (leaving 3 latest versions)... ";
rm -rf ${KERNEL_PATCH_PATH}
dnf autoremove -y
# shellcheck disable=SC2046
dnf remove -y $(dnf repoquery --installonly --latest-limit=-3 -q)

echo >&2 "===]> Info: Kernel update was finished successfully! ";
