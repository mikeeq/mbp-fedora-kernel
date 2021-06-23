#!/bin/bash

set -eu -o pipefail

cd /var/repo

# https://koji.fedoraproject.org/koji/packageinfo?packageID=6684
GRUB_MAIN_VERSION=2.04
GRUB_SUFFIX_VERSION=31
GRUB_FEDORA_VERSION=fc34

### Download previous versions of kernel
# wget -A rpm -r http://fedora-mbp-repo.herokuapp.com/
# # && wget -A xml -r http://fedora-mbp-repo.herokuapp.com/
# # && wget -A xml.gz -r http://fedora-mbp-repo.herokuapp.com/
# && mv -f ./fedora-mbp-repo.herokuapp.com/*.rpm ./
# # && mv -f ./fedora-mbp-repo.herokuapp.com/repodata ./
# && rm -rfv fedora-mbp-repo.herokuapp.com

### Download older version of grub 2.04
# grub_pkgs_x86_64=(
#   grub2-efi-ia32
#   grub2-efi-ia32-cdboot
#   grub2-efi-x64
#   grub2-efi-x64-cdboot
#   grub2-pc
#   grub2-tools
#   grub2-tools-efi
#   grub2-tools-extra
#   grub2-tools-minimal
# )

# grub_pkgs_noarch=(
#   grub2-common
#   grub2-pc-modules
#   grub2-efi-x64-modules
#   grub2-efi-ia32-modules
# )

# for i in "${grub_pkgs_x86_64[@]}"; do
#   curl -Ls https://kojipkgs.fedoraproject.org//packages/grub2/"${GRUB_MAIN_VERSION}"/"${GRUB_SUFFIX_VERSION}"."${GRUB_FEDORA_VERSION}"/x86_64/"${i}"-"${GRUB_MAIN_VERSION}"-"${GRUB_SUFFIX_VERSION}"."${GRUB_FEDORA_VERSION}".x86_64.rpm -O
# done

# for i in "${grub_pkgs_noarch[@]}"; do
#   curl -Ls https://kojipkgs.fedoraproject.org//packages/grub2/"${GRUB_MAIN_VERSION}"/"${GRUB_SUFFIX_VERSION}"."${GRUB_FEDORA_VERSION}"/noarch/"${i}"-"${GRUB_MAIN_VERSION}"-"${GRUB_SUFFIX_VERSION}"."${GRUB_FEDORA_VERSION}".noarch.rpm -O
# done

curl -Ls https://kojipkgs.fedoraproject.org//packages/shim/15/8/x86_64/shim-ia32-15-8.x86_64.rpm -O
curl -Ls https://kojipkgs.fedoraproject.org//packages/shim/15/8/x86_64/shim-x64-15-8.x86_64.rpm -O

### Download RELEASE_VERSION of kernel
for rpm in $(curl -s https://github.com/mikeeq/mbp-fedora-kernel/releases/v"${RELEASE_VERSION}" -L | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1); do
  wget --backups=1 https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v"${RELEASE_VERSION}"/"$rpm";
done \

### Remove caches and fix permissions
rm -rfv ./*.1
chown -R nginx:nginx /var/repo
