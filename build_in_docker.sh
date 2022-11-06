#!/bin/bash

set -eu -o pipefail

DOCKER_IMAGE=fedora:37
#DOCKER_IMAGE=fedora:36
# DOCKER_IMAGE=fedora_build:34
RPMBUILD_HOST_PATH=~/rpmbuild

mkdir -p ${RPMBUILD_HOST_PATH}

RPM_SIGNING_KEY=${RPM_SIGNING_KEY:-$(gpg --export-secret-keys -a 'mbp-fedora' | base64)}

docker pull ${DOCKER_IMAGE}
docker run \
  -t --network=host \
  --rm \
  -e RPM_SIGNING_KEY="$RPM_SIGNING_KEY" \
  -v "$(pwd)":/repo \
  -v ${RPMBUILD_HOST_PATH}:/root/rpmbuild \
  -w /repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c './build.sh'
