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
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Eclipse Temurin JDK 25 (more reliable than Debian package)
RUN mkdir -p /usr/share/man/man1 && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public -o /etc/apt/keyrings/adoptium.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
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
# Fix Flutter channel warnings
ENV FLUTTER_GIT_URL=https://github.com/flutter/flutter.git

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
    flutter precache --android --no-web --no-linux --no-windows --no-macos --no-ios --no-fuchsia && \
    find ${FLUTTER_HOME}/bin/cache -type f \( -name "*.zip" -o -name "*.tar.xz" -o -name "*.tar.gz" \) -delete && \
    rm -rf ${FLUTTER_HOME}/bin/cache/downloads

# Set permissions
RUN chown -R 1000:1000 ${FLUTTER_HOME} ${ANDROID_HOME}

USER ${USER}

# Clean up and verify installation
RUN flutter doctor --android-licenses && \
    flutter doctor
