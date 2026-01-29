FROM mcr.microsoft.com/devcontainers/base:debian

ARG VERSION=3.38.8
ARG USER=vscode

VOLUME [ "/opt" ]

# Set up environment variables
ENV JAVA_HOME=/opt/jdk
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${JAVA_HOME}/bin:${PATH}"
# Fix Flutter channel warnings
ENV FLUTTER_GIT_URL=https://github.com/flutter/flutter.git

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
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Download and install JDK 21 manually to /opt/jdk
RUN JDK_VERSION="21.0.2" && \
    JDK_BUILD="13" && \
    JDK_ARCHIVE="OpenJDK21U-jdk_x64_linux_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz" && \
    JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-${JDK_VERSION}%2B${JDK_BUILD}/${JDK_ARCHIVE}" && \
    echo "Downloading JDK from: ${JDK_URL}" && \
    mkdir -p /opt/jdk && \
    cd /tmp && \
    curl -L -o ${JDK_ARCHIVE} ${JDK_URL} && \
    tar -xzf ${JDK_ARCHIVE} -C /opt/jdk --strip-components=1 && \
    rm -f ${JDK_ARCHIVE} && \
    # Verify installation
    /opt/jdk/bin/java -version


# Install Android SDK command line tools only
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip cmdline-tools.zip && \
    rm cmdline-tools.zip && \
    mv cmdline-tools latest

# Accept licenses and install only essential SDK components (minimal set)
RUN yes | sdkmanager --licenses && \
    sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" && \
    rm -rf ${ANDROID_HOME}/.download ${ANDROID_HOME}/.temp ${ANDROID_HOME}/licenses && \
    find ${ANDROID_HOME} -name "*.exe" -delete && \
    find ${ANDROID_HOME} -name "*.dll" -delete

# Install Flutter with minimal footprint (for Android development only)
RUN git clone --depth 1 --branch ${VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    cd ${FLUTTER_HOME} && git gc --prune=now && \
    flutter precache && \
    find ${FLUTTER_HOME}/bin/cache -type f \( -name "*.zip" -o -name "*.tar.xz" -o -name "*.tar.gz" \) -delete && \
    rm -rf ${FLUTTER_HOME}/bin/cache/downloads

# Set permissions
RUN chown -R 1000:1000 ${FLUTTER_HOME} ${ANDROID_HOME}

USER ${USER}

# Clean up and verify installation
RUN yes | flutter doctor --android-licenses \
    && flutter doctor
