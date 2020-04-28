#!/bin/bash

set -eu -o pipefail

DOCKER_IMAGE=fedora:32
RPMBUILD_HOST_PATH=/opt/rpmbuild

mkdir -p ${RPMBUILD_HOST_PATH}

docker pull ${DOCKER_IMAGE}
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  -v ${RPMBUILD_HOST_PATH}:/root/rpmbuild \
  ${DOCKER_IMAGE} \
  /bin/bash -c 'cd /repo && ./build.sh'
