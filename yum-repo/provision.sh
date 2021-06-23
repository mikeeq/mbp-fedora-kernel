#!/bin/bash

set -eu -o pipefail

cd /var/repo

### Download previous versions of kernel
# wget -A rpm -r http://fedora-mbp-repo.herokuapp.com/
# # && wget -A xml -r http://fedora-mbp-repo.herokuapp.com/
# # && wget -A xml.gz -r http://fedora-mbp-repo.herokuapp.com/
# && mv -f ./fedora-mbp-repo.herokuapp.com/*.rpm ./
# # && mv -f ./fedora-mbp-repo.herokuapp.com/repodata ./
# && rm -rfv fedora-mbp-repo.herokuapp.com

### Download older version of shim
## shim 15.4-4 or -5 is not working on MBP 16,2
# https://koji.fedoraproject.org/koji/packageinfo?packageID=14502
curl -Ls https://kojipkgs.fedoraproject.org//packages/shim/15/8/x86_64/shim-ia32-15-8.x86_64.rpm -O
curl -Ls https://kojipkgs.fedoraproject.org//packages/shim/15/8/x86_64/shim-x64-15-8.x86_64.rpm -O

### Download RELEASE_VERSION of kernel
for rpm in $(curl -s https://github.com/mikeeq/mbp-fedora-kernel/releases/v"${RELEASE_VERSION}" -L | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1); do
  wget --backups=1 https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v"${RELEASE_VERSION}"/"$rpm";
done \

### Remove caches and fix permissions
rm -rfv ./*.1
chown -R nginx:nginx /var/repo
