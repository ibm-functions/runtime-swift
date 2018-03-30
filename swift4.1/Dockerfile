# Dockerfile extends Apache OpenWhisk Swift image https://github.com/apache/incubator-openwhisk-runtime-swift/blob/master/core/swift41Action/Dockerfile
# Using git hash https://github.com/apple/swift/commit/f01501c324876fc07820dc28923d7088fb7af847
FROM openwhisk/action-swift-v4.1:1.0.4

# Add Pre-Installed Pacakges for IBM
ADD spm-build/Package.swift /swift4Action/spm-build

# Build
RUN rm /swift4Action/spm-build/swiftbuildandlink.sh
RUN python /swift4Action/buildandrecord.py && rm /swift4Action/spm-build/.build/release/Action
#RUN cd /swift4Action/spm-build; swift build -v -c release; rm /swift4Action/spm-build/.build/release/Action