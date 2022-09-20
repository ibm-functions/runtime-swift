# Extend Apache OpenWhisk Swift v4.2 image: https://github.com/apache/openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
FROM openwhisk/action-swift-v4.2:43eef06 AS parent_image


# from https://github.com/apache/openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
# Build go action-loop proxy from source.
FROM golang:1.18 AS builder_source
ARG GO_PROXY_GITHUB_USER=apache
ARG GO_PROXY_GITHUB_BRANCH=master
RUN git clone --branch ${GO_PROXY_GITHUB_BRANCH} \
   https://github.com/${GO_PROXY_GITHUB_USER}/openwhisk-runtime-go /src &&\
   cd /src && env GO111MODULE=on CGO_ENABLED=0 go build main/proxy.go && \
   mv proxy /bin/proxy

# Build go action-loop proxy from release.
FROM golang:1.18 AS builder_release
ARG GO_PROXY_RELEASE_VERSION=1.15@1.18.0
RUN curl -sL \
  https://github.com/apache/openwhisk-runtime-go/archive/{$GO_PROXY_RELEASE_VERSION}.tar.gz\
  | tar xzf -\
  && cd openwhisk-runtime-go-*/main\
  && GO111MODULE=on go build -o /bin/proxy


# Now start the main image.
# from https://github.com/apple/swift-docker/blob/main/4.2/ubuntu/18.04/Dockerfile
FROM ubuntu:18.04

# Upgrade to get latest security fixes, install Swift related packages and set LLVM 3.9 as the compiler.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    # Update installed packages to get security fixes when available.
    apt-get upgrade -y --no-install-recommends --with-new-pkgs && \
    # Install swift required packages.
    apt-get -q install -y \
    make \
    libc6-dev \
    clang-3.9 \
    curl \
    libedit-dev \
    libpython2.7 \
    libicu-dev \
    libssl-dev \
    libxml2 \
    tzdata \
    git \
    libcurl4-openssl-dev \
    zlib1g-dev \
    pkg-config \
    # following packages from: https://github.com/apache/openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
    locales python3 vim \
    && update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.9 100 \
    && update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.9 100 \
    # from: https://github.com/apache/openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
    && locale-gen en_US.UTF-8 \
    # Cleanup package lists, not required anymore.
    && rm -r /var/lib/apt/lists/*

# Set swift variables and environment.
ARG SWIFT_PLATFORM=ubuntu18.04
ARG SWIFT_BRANCH=swift-4.2.4-release
ARG SWIFT_VERSION=swift-4.2.4-RELEASE

ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION

# Download GPG keys, signature and Swift package, then unpack, cleanup and execute permissions for foundation libs.
# https://download.swift.org/swift-4.2.4-release/ubuntu1804/swift-4.2.4-RELEASE/swift-4.2.4-RELEASE-ubuntu18.04.tar.gz
RUN set -x \
    && SWIFT_URL=https://download.swift.org/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz \
    && curl -fSsL $SWIFT_URL -o swift.tar.gz \
    && curl -fSsL $SWIFT_URL.sig -o swift.tar.gz.sig \
    && export GNUPGHOME="$(mktemp -d)" \
    && set -e; \
        for key in \
      # pub   rsa4096 2017-11-07 [SC] [expires: 2019-11-07]
      # 8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4
      # uid           [ unknown] Swift Automatic Signing Key #2 <swift-infrastructure@swift.org>
          8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4 \
      # pub   4096R/91D306C6 2016-05-31 [expires: 2018-05-31]
      #       Key fingerprint = A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6
      # uid                  Swift 3.x Release Signing Key <swift-infrastructure@swift.org>
          A3BAFD3556A59079C06894BD63BC1CFE91D306C6 \
      # pub   4096R/71E1B235 2016-05-31 [expires: 2019-06-14]
      #       Key fingerprint = 5E4D F843 FB06 5D7F 7E24  FBA2 EF54 30F0 71E1 B235
      # uid                  Swift 4.x Release Signing Key <swift-infrastructure@swift.org>
          5E4DF843FB065D7F7E24FBA2EF5430F071E1B235 \
        ; do \
          # gpg --quiet --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
          gpg --quiet --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
        done \
    && gpg --batch --verify --quiet swift.tar.gz.sig swift.tar.gz \
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && rm -r "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz || true \
    && chmod -R o+r /usr/lib/swift \
    # Print Installed Swift Version
    && swift --version


# from https://github.com/apache/openwhisk-runtime-swift/blob/master/core/swift42Action/Dockerfile
# Select the action-loop proxy build to activate for this image (release/source).
ARG GO_PROXY_BUILD_FROM=release


# Get the /swiftAction directory from parent_image.
COPY --from=parent_image /swiftAction /swiftAction

# Set active workdir to the action directory.
WORKDIR /swiftAction

# Get compiled action-loop proxy from builder_source.
COPY --from=builder_source /bin/proxy /bin/proxy_source
# Get compiled action-loop proxy from builder_release.
COPY --from=builder_release /bin/proxy /bin/proxy_release

# Get the compiler invocation script from parent_image.
COPY --from=parent_image /bin/compile /bin/compile
# Get the compile.launcher.swift from parent_image.
COPY --from=parent_image /bin/compile.launcher.swift /bin/compile.launcher.swift

# Overwrite the default _Whisk.swift with an IBM Cloud adapted version.
COPY _Whisk.swift /swiftAction/Sources/

# Add Pre-Installed SDK Packages for IBM Cloud.
COPY Package.swift /swiftAction/

RUN \
    # Now choose which one is the active action-loop proxy.
    mv /bin/proxy_${GO_PROXY_BUILD_FROM} /bin/proxy \
    # Show actual proxy version in the build output.
    && /bin/proxy -version \
    # Build dummy main.swift to have SDKs already compiled to speed up later action execution.
    && swift build -c release \
    # Touch main.swift to force rebuild of it when compile is triggered next time (just to be sure).
    && touch /swiftAction/Sources/main.swift \
    # Remove generated Action binary, will be generated again when action code is injected later on.
    && rm /swiftAction/.build/release/Action \
    && /swiftAction/buildandrecord.py

# Some environment vars for the action execution environment.
ENV OW_COMPILER=/bin/compile \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

# Run the action-loop proxy when starting the container.
ENTRYPOINT [ "/bin/proxy" ]
