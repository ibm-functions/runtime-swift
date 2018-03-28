# Dockerfile extends Apache OpenWhisk Swift image https://github.com/apache/incubator-openwhisk-runtime-swift/blob/master/core/swift41Action/Dockerfile
FROM openwhisk/action-swift-v4.1:1.0.3

# Add Pre-Installed Pacakges for IBM
ADD spm-build/Package.swift /swift4Action/spm-build

# Build
RUN rm /swift4Action/spm-build/swiftbuildandlink.sh
RUN python /swift4Action/buildandrecord.py && rm /swift4Action/spm-build/.build/release/Action
#RUN cd /swift4Action/spm-build; swift build -v -c release; rm /swift4Action/spm-build/.build/release/Action