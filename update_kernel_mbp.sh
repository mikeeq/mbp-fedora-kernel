#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
KERNEL_PATCH_PATH=/tmp/kernel_patch

UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-v5.18-f36}

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

if curl -sf -LI "https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/update_kernel_mbp.sh"; then
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

### Download kernel packages
KERNEL_PACKAGES=()

CURRENT_KERNEL_VERSION=$(uname -r)
echo >&2 "===]> Info: Current kernel version: ${CURRENT_KERNEL_VERSION}";

if [[ -n "${KERNEL_VERSION:-}" ]]; then
  MBP_KERNEL_TAG=${KERNEL_VERSION}
  echo >&2 "===]> Info: Downloading specified kernel: ${MBP_KERNEL_TAG}";

  while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL "https://github.com/mikeeq/mbp-fedora-kernel/releases/tag/v${MBP_KERNEL_TAG}" | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1)

  for i in "${KERNEL_PACKAGES[@]}"; do
    curl -LO "https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${MBP_KERNEL_TAG}/${i}"
  done

else
  echo >&2 "===]> Info: Installing latest kernel from repo";
  dnf update -y kernel kernel-core kernel-modules mbp-fedora-t2-config
fi

if rpm -q gpg-pubkey --qf '%{SUMMARY}\n' | grep -q -i mbp-fedora; then
  echo >&2 "===]> Info: fedora-mbp yum repo gpg key is already added, skipping...";
else
  echo >&2 "===]> Info: Adding fedora-mbp yum repo gpg key...";
  curl -sSL "https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/yum-repo/fedora-mbp.gpg" > ./fedora-mbp.gpg
  rpm --import ./fedora-mbp.gpg
  rm -rf ./fedora-mbp.gpg
fi

if dnf repolist | grep -iq fedora-mbp; then
  echo >&2 "===]> Info: fedora-mbp repo was already added, skipping..."
else
  echo >&2 "===]> Info: Adding fedora-mbp repo..."
  curl -sSL "https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/yum-repo/fedora-mbp-external.repo" > /etc/yum.repos.d/fedora-mbp.repo
fi

### Cleanup
echo >&2 "===]> Info: Cleaning old kernel pkgs (leaving 3 latest versions)... ";
rm -rf ${KERNEL_PATCH_PATH}
dnf autoremove -y
# shellcheck disable=SC2046
dnf remove -y $(dnf repoquery --installonly --latest-limit=-3 -q)

echo >&2 "===]> Info: Kernel update to ${MBP_KERNEL_TAG} finished successfully! ";
