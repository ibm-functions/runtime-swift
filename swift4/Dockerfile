# Dockerfile for swift actions, overrides and extends ActionRunner from actionProxy
# This Dockerfile is partially based on: https://github.com/IBM-Swift/swift-ubuntu-docker/blob/master/swift-development/Dockerfile
FROM ibmcom/swift-ubuntu:4.0.3

# Set WORKDIR
WORKDIR /

# Upgrade and install basic Python dependencies
RUN apt-get -y update \
 && apt-get -y install --fix-missing python2.7 python-gevent python-flask zip

# Add the action proxy
# Add the action proxy
RUN mkdir -p /actionProxy
ADD actionproxy.py /actionProxy

# FIXME: once this issue is fixed https://github.com/apache/incubator-openwhisk-runtime-swift/issues/15
#RUN mkdir -p /actionProxy
#ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/dockerskeleton%401.0.0/core/actionProxy/actionproxy.py /actionProxy/actionproxy.py

# Add files needed to build and run action
RUN mkdir -p /swift4Action/spm-build/Sources/Action
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-swift/master/core/swift4Action/epilogue.swift /swift4Action/epilogue.swift
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-swift/master/core/swift4Action/buildandrecord.py /swift4Action/buildandrecord.py
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-swift/master/core/swift4Action/swift4runner.py /swift4Action/swift4runner.py
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-swift/master/core/swift4Action/spm-build/_Whisk.swift /swift4Action/spm-build/Sources/Action/_Whisk.swift

# Add Pre-Installed Pacakges
ADD spm-build/Package.swift /swift4Action/spm-build

# Build
RUN touch /swift4Action/spm-build/Sources/Action/main.swift
RUN python /swift4Action/buildandrecord.py && rm /swift4Action/spm-build/.build/release/Action
#RUN cd /swift4Action/spm-build; swift build -v -c release; rm /swift4Action/spm-build/.build/release/Action
ENV FLASK_PROXY_PORT 8080
EXPOSE 8080

CMD ["/bin/bash", "-c", "cd /swift4Action && PYTHONIOENCODING='utf-8' python -u swift4runner.py"]