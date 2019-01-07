# Dockerfile extends Apache OpenWhisk Swift image https://github.com/apache/incubator-openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
FROM csantanapr/action-swift-v4.2

# Add Pre-Installed Pacakges for IBM
COPY _Whisk.swift /swiftAction/Sources/
COPY Package.swift /swiftAction/
COPY buildandrecord.py /swiftAction/

COPY main.swift /swiftAction/Sources/
COPY swiftbuild.py /bin/compile
RUN swift build -c release; \
touch /swiftAction/Sources/main.swift; \
rm /swiftAction/.build/release/Action; \
/swiftAction/buildandrecord.py

