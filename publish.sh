#!/bin/bash

set -eu -o pipefail

set -x

# export HEROKU_API_KEY=
LATEST_RELEASE=$(curl -sI https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | grep -i "location:" | cut -d'v' -f2 | tr -d '\r')
echo >&2 "===]> Info: LATEST_RELEASE=$LATEST_RELEASE"

# echo "Release: ${LATEST_RELEASE}"

# cd yum-repo || exit

# # Download heroku-cli
# curl https://cli-assets.heroku.com/install.sh | sh

# heroku container:login
# heroku container:push -a mbp-fedora-repo web --arg RELEASE_VERSION="${LATEST_RELEASE}"
# heroku container:release -a mbp-fedora-repo web


cd yum-repo
docker build -t mbp-fedora-repo --build-arg RELEASE_VERSION="${LATEST_RELEASE}" .

DOCKER_CONTAINER_ID=$(docker run -d -p 8080:8080 mbp-fedora-repo)
docker exec -t -u 0 $DOCKER_CONTAINER_ID /bin/bash -c '
dnf makecache
dnf install -y zip
zip -r /tmp/repo.zip /var/repo
'
docker cp $DOCKER_CONTAINER_ID:/tmp/repo.zip /tmp/repo.zip
# git checkout gh-pages
# unzip
# chown
# commit
# push
