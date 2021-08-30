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

# Work around for the missing azure-storage-blob:12.6.0 issue.
# Version 12.6.0 was removed from maven central. Patching the code to use 12.7.0 instead.
# Adapting to an updated version of apache/openwhisk takes some more effort and will be done later on.
echo "Update openwhisk/common/scala/build.gradle to azure-storage-blob:12.7.0"
sed -i "s/com\.azure:azure-storage-blob:12\.6\.0/com.azure:azure-storage-blob:12.7.0/" common/scala/build.gradle

./tools/travis/setup.sh

