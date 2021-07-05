#!/bin/bash
set -ex

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"

export OPENWHISK_HOME=$WHISKDIR

IMAGE_PREFIX="testing"

# Login to hub.docker.com to get user specific pull rate.
if [ ! -z "${DOCKER_USER}" ] && [ ! -z "${DOCKER_PASSWORD}" ]; then
  echo "Run docker login..."
  echo ${DOCKER_PASSWORD} | docker login -u "${DOCKER_USER}" --password-stdin
fi

# Build OpenWhisk
cd $WHISKDIR

#pull down images
docker pull openwhisk/controller:nightly
docker tag openwhisk/controller:nightly ${IMAGE_PREFIX}/controller
docker pull openwhisk/invoker:nightly
docker tag openwhisk/invoker:nightly ${IMAGE_PREFIX}/invoker
docker pull openwhisk/nodejs6action:nightly
docker tag openwhisk/nodejs6action:nightly nodejs6action

TERM=dumb ./gradlew install

# install new version docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
docker version

# Build runtime
cd $ROOTDIR
TERM=dumb ./gradlew \
:swift4.2:distDocker \
:swift5.4:distDocker \
-PdockerImagePrefix=${IMAGE_PREFIX}
