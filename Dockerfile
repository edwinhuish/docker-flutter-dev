ARG VERSION=3.38.8
ARG ANDROID_VERSION=36
ARG JDK_VERSION=25
ARG USER=vscode

# Stage 1: Android SDK
FROM ghcr.io/cirruslabs/android-sdk:${ANDROID_VERSION} AS android-sdk-image

# Stage 2: Java SDK  
FROM eclipse-temurin:${JDK_VERSION} AS java-sdk-image

# Stage 3: Main development container
FROM mcr.microsoft.com/devcontainers/base:debian

ARG USER
ARG VERSION


# 替换 sources
# debian
RUN if [ -f /etc/apt/sources.list ]; then \
        sed -i 's|http://deb.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list \
        && sed -i 's|https://security.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list; \
    fi

# debian 13
RUN if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
        sed -i 's|http://deb.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list.d/debian.sources \
        && sed -i 's|https://security.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list.d/debian.sources; \
    fi

# Install linux dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
    apt-get install -y --no-install-recommends \
    clang cmake ninja-build pkg-config libgtk-3-dev &&\
    apt dist-upgrade -y

# Get Android SDK from stage 1
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
COPY --from=android-sdk-image $ANDROID_HOME $ANDROID_HOME
RUN mkdir -p $ANDROID_HOME/cmdline-tools/latest &&\
    (cd $ANDROID_HOME/cmdline-tools && ls | grep -v latest | xargs -I {} mv {} latest/)
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Get Java SDK from stage 2
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=java-sdk-image $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Get latest Flutter
ENV FLUTTER_HOME=/usr/bin/flutter
RUN mkdir -p $FLUTTER_HOME &&\
    git clone --depth 1 --branch ${VERSION} git@github.com:flutter/flutter.git $FLUTTER_HOME && \
    rm -rf $FLUTTER_HOME/.git

ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
RUN chmod +x $FLUTTER_HOME/bin/flutter &&\
    git config --global --add safe.directory '*' &&\
    flutter precache

# Enable flutter bash completion
RUN $FLUTTER_HOME/bin/flutter bash-completion > /etc/profile.d/flutter_bash_completion.sh
RUN echo 'export PATH="\$PATH:\$HOME/.pub-cache/bin"' >> /etc/profile.d/path_pub_cache.sh

# Install flutter bash completion
RUN chown 1000:1000 $FLUTTER_HOME -R &&\
    chown 1000:1000 $JAVA_HOME -R &&\
    chown 1000:1000 $ANDROID_HOME -R
USER ${USER}

# Print version && health check
RUN sdkmanager --version &&\
    java --version &&\
    flutter doctor


# 使用清华镜像源加速 Flutter 依赖下载
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
