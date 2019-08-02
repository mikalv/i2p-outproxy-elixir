#!/bin/bash
set -e
GIT_VERSION=`git describe --always --tags | cut -c 2-`

working_dir=$(pwd)

if [[ $working_dir == *"/deploy" ]]; then
  cd ..
fi

mkdir -p deploy/tmp/

docker build -f Dockerfile.releaser -t app:releaser .

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
RELEASE_FILE_PATH=/app/_build/prod/rel/app/releases/0.1.0/app.tar.gz

docker run --name app_releaser_${DOCKER_UUID} app:releaser /bin/true
docker cp app_releaser_${DOCKER_UUID}:${RELEASE_FILE_PATH} deploy/tmp/
docker rm app_releaser_${DOCKER_UUID}

