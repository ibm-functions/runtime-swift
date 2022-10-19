#!/bin/bash
set -eux

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"

export OPENWHISK_HOME=$WHISKDIR

IMAGE_PREFIX=$1
RUNTIME_VERSION=$2
IMAGE_TAG=$3


if [ ${RUNTIME_VERSION} == "4.1" ]; then
  RUNTIME="swift4.1"
elif [ ${RUNTIME_VERSION} == "4.2" ]; then
  RUNTIME="swift4.2"
fi

if [[ ! -z ${DOCKER_USER} ]] && [[ ! -z ${DOCKER_PASSWORD} ]]; then
docker login -u "${DOCKER_USER}" -p "${DOCKER_PASSWORD}"
fi

if [[ ! -z ${RUNTIME} ]]; then
TERM=dumb ./gradlew \
:${RUNTIME}:pushImage \
-PdockerRegistry=docker.io \
-PdockerImagePrefix=${IMAGE_PREFIX} \
-PdockerImageTag=${IMAGE_TAG}

  # if doing latest also push a tag with the hash commit
  if [ ${IMAGE_TAG} == "master" ]; then
  SHORT_COMMIT=`git rev-parse --short HEAD`
  TERM=dumb ./gradlew \
  :${RUNTIME}:pushImage \
  -PdockerRegistry=docker.io \
  -PdockerImagePrefix=${IMAGE_PREFIX} \
  -PdockerImageTag=${SHORT_COMMIT}
  fi

fi
