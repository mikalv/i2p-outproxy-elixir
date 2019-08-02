#!/usr/bin/env bash
GIT_VERSION=`git describe --always --tags | cut -c 2-`

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
#npm install --prefix ./assets
#npm run deploy --prefix ./assets

# Remove the existing release directory and build the release
rm -rf "_build"
MIX_ENV=prod mix release

