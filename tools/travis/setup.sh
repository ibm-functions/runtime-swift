#!/bin/bash
set -e

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
HOMEDIR="$SCRIPTDIR/../../../"

# OpenWhisk stuff
cd $HOMEDIR
# git clone --depth=1 https://github.com/apache/incubator-openwhisk.git openwhisk

git clone https://github.com/apache/openwhisk.git openwhisk
cd openwhisk
# Use a fixed commit to run the tests, to explicitly control when changes are consumed.
# Commit:  Update the notice year (#5122) 
git checkout ecb2a980659f28d0adbd9ef837afaf4cb2b695bf


./tools/travis/setup.sh

