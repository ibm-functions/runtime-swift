#!/bin/bash
set -e

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
HOMEDIR="$SCRIPTDIR/../../../"

# OpenWhisk stuff
cd $HOMEDIR
git clone --depth=1 --single-branch -b scala-2-12 https://github.com/chetanmeh/incubator-openwhisk.git openwhisk
cd openwhisk
./tools/travis/setup.sh

