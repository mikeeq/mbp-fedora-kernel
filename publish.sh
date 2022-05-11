#!/bin/bash

set -eu -o pipefail

# export HEROKU_API_KEY=
LATEST_RELEASE=$(curl -Is https://github.com/mikeeq/mbp-fedora-kernel/releases/latest | grep -i 'location:' | cut -f2 -d'v' | cut -f1 -d'"' | tr '\r' '\n' )

echo "Release: ${LATEST_RELEASE}"

cd yum-repo || exit

# Download heroku-cli
curl https://cli-assets.heroku.com/install.sh | sh

heroku container:login
heroku container:push -a fedora-mbp-repo web --arg RELEASE_VERSION="${LATEST_RELEASE}"
heroku container:release -a fedora-mbp-repo web
