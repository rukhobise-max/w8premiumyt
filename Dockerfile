FROM google/android-ndk:r25-ubuntu

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
WORKDIR /opt
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1
ENV PATH="/opt/flutter/bin:${PATH}"

# Accept Android SDK licenses
RUN yes | flutter doctor --android-licenses

# Create app directory
WORKDIR /app

# Copy project files
COPY android_app/ ./android_app/
COPY frontend/ ./frontend/

# Get Flutter dependencies
WORKDIR /app/android_app
RUN flutter clean && flutter pub get

# Build APK
RUN flutter build apk --release

# Output directory
RUN mkdir -p /output && \
    cp build/app/outputs/apk/release/app-release.apk /output/

VOLUME /output
CMD ["cp", "-r", "build/app/outputs/apk/release/app-release.apk", "/output/"]
