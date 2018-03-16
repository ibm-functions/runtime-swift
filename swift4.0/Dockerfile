# Dockerfile for swift actions, overrides and extends ActionRunner from actionProxy
FROM openwhisk/action-swift-v4.0:1.0.1

# Add Pre-Installed Pacakges for IBM
ADD spm-build/Package.swift /swift4Action/spm-build

# TODO replace with upstream when issue gets promoted https://github.com/apache/incubator-openwhisk-runtime-swift/pull/23
ADD epilogue.swift /swift4Action
ADD spm-build/_Whisk.swift /swift4Action/spm-build/Sources/Action
ADD swift4runner.py /swift4Action/swift4runner.py

# Build
RUN touch /swift4Action/spm-build/Sources/Action/main.swift
RUN rm /swift4Action/spm-build/swiftbuildandlink.sh
RUN python /swift4Action/buildandrecord.py && rm /swift4Action/spm-build/.build/release/Action
#RUN cd /swift4Action/spm-build; swift build -v -c release; rm /swift4Action/spm-build/.build/release/Action
