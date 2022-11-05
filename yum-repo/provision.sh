#!/bin/bash

set -eu -o pipefail

cd /var/repo

### Download previous versions of kernel from running yum repo
# wget -A rpm -r http://mbp-fedora-repo.herokuapp.com/
# mv -f ./mbp-fedora-repo.herokuapp.com/*.rpm ./
# rm -rfv mbp-fedora-repo.herokuapp.com


### shim 15.6-2 is now working properly on MBP 16,2
### Download older version of shim
## shim 15.4-4 or -5 is not working on MBP 16,2
# https://koji.fedoraproject.org/koji/packageinfo?packageID=14502
# curl -Ls https://kojipkgs.fedoraproject.org/packages/shim/15/8/x86_64/shim-ia32-15-8.x86_64.rpm -O
# curl -Ls https://kojipkgs.fedoraproject.org/packages/shim/15/8/x86_64/shim-x64-15-8.x86_64.rpm -O

### Download RELEASE_VERSION of kernel
for rpm in $(curl -sL "https://github.com/mikeeq/mbp-fedora-kernel/releases/expanded_assets/v${RELEASE_VERSION}" | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1); do
  curl -Ls "https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/${rpm}" -O
done

### Remove caches and fix permissions
rm -rfv ./*.1
chown -R nginx:nginx /var/repo
