# Dockerfile extends Apache OpenWhisk Swift image https://github.com/apache/openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
FROM openwhisk/action-swift-v5.4:5dc532c

# Add Pre-Installed Packages for IBM
COPY _Whisk.swift /swiftAction/Sources/
COPY Package.swift /swiftAction/
RUN apt-get update \
    # Update installed packages to get security fixes if available.
    && apt-get upgrade -y --no-install-recommends --with-new-pkgs\
    # Cleanup apt data, we do not need them later on.
    && rm -rf /var/lib/apt/lists/* \
    && swift build -c release \
    && touch /swiftAction/Sources/main.swift \
    && rm /swiftAction/.build/release/Action

