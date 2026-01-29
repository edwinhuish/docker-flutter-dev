FROM mcr.microsoft.com/devcontainers/base:debian

ARG VERSION=3.38.8
ARG USER=vscode

# Install minimal required dependencies only
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    wget \
    libgl1 \
    lib32z1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Eclipse Temurin JDK 25 (more reliable than Debian package)
RUN mkdir -p /usr/share/man/man1 && \
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - && \
    echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends temurin-25-jdk && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Set up environment variables
ENV JAVA_HOME=/usr/lib/jvm/temurin-25-jdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${JAVA_HOME}/bin:${PATH}"

# Install Android SDK command line tools only
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip cmdline-tools.zip && \
    rm cmdline-tools.zip && \
    mv cmdline-tools latest

# Accept licenses and install only essential SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" && \
    rm -rf ${ANDROID_HOME}/.download ${ANDROID_HOME}/.temp ${ANDROID_HOME}/licenses

# Install Flutter with minimal footprint
RUN git clone --depth 1 --branch ${VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter precache --universal --android --no-web --no-linux --no-windows --no-macos --no-ios --no-fuchsia && \
    find ${FLUTTER_HOME}/bin/cache -type f -name "*.zip" -delete && \
    find ${FLUTTER_HOME}/bin/cache -type f -name "*.tar.xz" -delete && \
    rm -rf ${FLUTTER_HOME}/.git

# Set permissions
RUN chown -R 1000:1000 ${FLUTTER_HOME} ${ANDROID_HOME}

USER ${USER}

# Verify installation
RUN flutter doctor
