#!/bin/sh

# export HEROKU_API_KEY=
LATEST_RELEASE=$(curl -s https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | cut -d'v' -f2 | cut -d'"' -f1)

echo "Release: ${LATEST_RELEASE}"

cd yum-repo

# Download heroku-cli
curl https://cli-assets.heroku.com/install.sh | sh

heroku container:login
heroku container:push -a fedora-mbp-repo web --arg RELEASE_VERSION=${LATEST_RELEASE}
heroku container:release -a fedora-mbp-repo web

# Docker build
# docker build -t fedora-mbp-repo --build-arg RELEASE_VERSION=${LATEST_RELEASE} .
