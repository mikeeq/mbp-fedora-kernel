#!/bin/bash

set -eu -o pipefail

DOCKER_IMAGE=fedora:35
# DOCKER_IMAGE=fedora_build:35
RPMBUILD_HOST_PATH=~/rpmbuild

mkdir -p ${RPMBUILD_HOST_PATH}

# docker pull ${DOCKER_IMAGE}
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  -v ${RPMBUILD_HOST_PATH}:/root/rpmbuild \
  ${DOCKER_IMAGE} \
  /bin/bash -c 'cd /repo && ./build.sh'
