#!/bin/bash
set -ex

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"

export OPENWHISK_HOME=$WHISKDIR

IMAGE_PREFIX="testing"

# Build OpenWhisk
cd $WHISKDIR

#pull down images
docker pull openwhisk/controller
docker tag openwhisk/controller ${IMAGE_PREFIX}/controller
docker pull openwhisk/invoker
docker tag openwhisk/invoker ${IMAGE_PREFIX}/invoker
docker pull openwhisk/nodejs6action
docker tag openwhisk/nodejs6action nodejs6action

TERM=dumb ./gradlew install

# install new version docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
docker version

# Build runtime
cd $ROOTDIR
TERM=dumb ./gradlew \
:swift4.1:distDocker \
:swift4.2:distDocker \
-PdockerImagePrefix=${IMAGE_PREFIX}
