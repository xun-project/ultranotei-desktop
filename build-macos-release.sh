#!/bin/bash
set -e

# Try to detect Qt
if [ -z "$QT_DIR" ]; then
    # User provided path
    USER_QT_PATH="/Users/desp/Qt5.14.2/5.14.2/clang_64"
    if [ -d "$USER_QT_PATH" ]; then
        QT_DIR="$USER_QT_PATH"
    elif brew --prefix qt@5 > /dev/null 2>&1; then
        DETECTED_QT=$(brew --prefix qt@5)
        if [ -d "$DETECTED_QT" ]; then
            QT_DIR=$DETECTED_QT
        fi
    elif brew --prefix qt > /dev/null 2>&1; then
        DETECTED_QT=$(brew --prefix qt)
        if [ -d "$DETECTED_QT" ]; then
            QT_DIR=$DETECTED_QT
        fi
    fi

    if [ -z "$QT_DIR" ]; then
        echo "Error: Qt 5 not found. Please set QT_DIR."
        exit 1
    fi
fi

echo "Using Qt at: $QT_DIR"

# Clean previous build
rm -rf build/release

# Initialize submodules
# Initialize submodules
git submodule update --init --recursive --remote --depth 1

# Build Tor dependencies
chmod +x ./tor_build.sh
./tor_build.sh

# Prepare build directory
mkdir -p build/release
cd build/release

# Configure CMake
# Added -DCMAKE_PREFIX_PATH explicit pointing to lib/cmake if needed, but often just the prefix works.
# But for Qt5 specifically, CMAKE_PREFIX_PATH should point to the root or ensure cmake finds it.
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$QT_DIR/lib/cmake" -DQT5_ROOT_PATH="$QT_DIR" ../..

# Build
make -j$(sysctl -n hw.ncpu)

# Package
make package
