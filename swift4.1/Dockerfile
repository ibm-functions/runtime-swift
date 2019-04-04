# Dockerfile extends Apache OpenWhisk Swift image https://github.com/apache/incubator-openwhisk-runtime-swift/blob/master/core/swift41Action/Dockerfile
# Using git hash https://github.com/apple/swift/commit/4432bfb0c5cf817119ee88ba6108e7c97e13a331
FROM openwhisk/action-swift-v4.1:019024d

# Add Pre-Installed Pacakges for IBM
COPY spm-build/Package.swift /swift4Action/spm-build/Package.swift
COPY spm-build/_Whisk.swift /swift4Action/spm-build/Sources/Action/_Whisk.swift

# Build
RUN rm /swift4Action/spm-build/swiftbuildandlink.sh
RUN python /swift4Action/buildandrecord.py && rm /swift4Action/spm-build/.build/release/Action
#RUN cd /swift4Action/spm-build; swift build -v -c release; rm /swift4Action/spm-build/.build/release/Action
