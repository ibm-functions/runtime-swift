#!/bin/bash
set -ex

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"

#Deployment
WHISK_CLI="${WHISKDIR}/bin/wsk -i"

# Run a simple action using the kind
${WHISK_CLI} action update echoSwift40 ${ROOTDIR}/tests/dat/actions/echo/main.swift --kind "swift:4.0"
${WHISK_CLI} action invoke echoSwift40 -b -p kind swift40
${WHISK_CLI} action update echoSwift41 ${ROOTDIR}/tests/dat/actions/echo/main.swift --kind "swift:4.1"
${WHISK_CLI} action invoke echoSwift41 -b -p kind swift41

export OPENWHISK_HOME=$WHISKDIR
cd ${ROOTDIR}
TERM=dumb ./gradlew :tests:checkScalafmtAll
if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  TERM=dumb ./gradlew :tests:test
else
  TERM=dumb ./gradlew :tests:testWithoutCredentials
fi
