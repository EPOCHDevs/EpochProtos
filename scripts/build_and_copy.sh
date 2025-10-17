#!/bin/bash

# DEPRECATED: This script is deprecated as of EpochProtos v2.0.8+
#
# The recommended approach is to use CMake FetchContent or CPM to build EpochProtos from source.
# This ensures all code is compiled with the same dependency versions, avoiding ABI mismatches.
#
# Example usage in your CMakeLists.txt:
#   include(FetchContent)
#   set(BUILD_PYTHON_PROTOS OFF CACHE BOOL "")
#   set(BUILD_TYPESCRIPT_PROTOS OFF CACHE BOOL "")
#   set(VCPKG_MANIFEST_MODE OFF)  # If using vcpkg in parent project
#   FetchContent_Declare(
#       EpochProtos
#       GIT_REPOSITORY https://github.com/EPOCHDevs/EpochProtos.git
#       GIT_TAG main
#   )
#   FetchContent_MakeAvailable(EpochProtos)
#   target_link_libraries(your_target PRIVATE epoch::protos)
#
# This script remains for legacy compatibility but may be removed in future versions.

# Script to build with CMake and copy generated headers and static library to local projects
# Usage: ./build_and_copy.sh [target_path]

set -e

# Set up vcpkg environment
export VCPKG_ROOT="${VCPKG_ROOT:-$HOME/vcpkg}"
export PATH="$VCPKG_ROOT/installed/x64-linux/tools/protobuf:$PATH"

# Default target path
DEFAULT_TARGET="/home/adesola/EpochLab/EpochDashboard/cpp/thirdparty/epoch_protos"

# Use provided target path or default
TARGET_PATH="${1:-$DEFAULT_TARGET}"

# Source paths
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${SOURCE_DIR}/build"

echo "EpochProtos Build and Copy Script"
echo "================================="
echo "Source directory: ${SOURCE_DIR}"
echo "Target directory: ${TARGET_PATH}"
echo ""

# Step 1: Build with CMake (skip if already built)
if [ -f "${BUILD_DIR}/.cpp_built" ] && [ -f "${BUILD_DIR}/libepoch_protos_cpp.a" ]; then
    echo "Step 1: C++ already built, skipping..."
    echo ""
else
    echo "Step 1: Building with CMake..."
    cd "${SOURCE_DIR}"

    # Create build directory
    mkdir -p build
    cd build

    # Configure with CMake
    echo "  Configuring with CMake..."
    cmake .. -DBUILD_PYTHON_PROTOS=OFF -DBUILD_TYPESCRIPT_PROTOS=OFF

    # Build
    echo "  Building..."
    make -j$(nproc)

    # Mark as built
    touch .cpp_built

    echo "  ✅ Build completed successfully!"
    echo ""
fi

# Step 2: Copy files
echo "Step 2: Copying files to local projects..."

# Create target directories
mkdir -p "${TARGET_PATH}/include/epoch_protos"
mkdir -p "${TARGET_PATH}/lib"

# Copy only our proto header files (not WKT)
echo "  Copying headers..."
for proto_file in common chart_def table_def tearsheet; do
    if [ -f "${BUILD_DIR}/${proto_file}.pb.h" ]; then
        cp "${BUILD_DIR}/${proto_file}.pb.h" "${TARGET_PATH}/include/epoch_protos/"
        echo "    Copied ${proto_file}.pb.h"
    fi
done

# Copy static library
echo "  Copying static library..."
if [ -f "${BUILD_DIR}/libepoch_protos_cpp.a" ]; then
    cp "${BUILD_DIR}/libepoch_protos_cpp.a" "${TARGET_PATH}/lib/"
    echo "    Copied libepoch_protos_cpp.a"
else
    # Find and copy any epoch_protos library
    EPOCH_LIB_FILES=$(find "${BUILD_DIR}" -name "libepoch_protos*.a" -type f)
    if [ -n "$EPOCH_LIB_FILES" ]; then
        echo "$EPOCH_LIB_FILES" | while read -r lib_file; do
            cp "$lib_file" "${TARGET_PATH}/lib/"
            echo "    Copied $(basename "$lib_file")"
        done
    else
        echo "    ⚠️  Warning: No epoch_protos static library found"
    fi
fi

# Copy CMake config files if they exist
echo "  Copying CMake config files..."
if [ -f "${BUILD_DIR}/EpochProtosConfig.cmake" ]; then
    mkdir -p "${TARGET_PATH}/cmake/EpochProtos"
    cp "${BUILD_DIR}/EpochProtosConfig.cmake" "${TARGET_PATH}/cmake/EpochProtos/"
    echo "    Copied EpochProtosConfig.cmake"
fi

if [ -f "${BUILD_DIR}/EpochProtosConfigVersion.cmake" ]; then
    cp "${BUILD_DIR}/EpochProtosConfigVersion.cmake" "${TARGET_PATH}/cmake/EpochProtos/"
    echo "    Copied EpochProtosConfigVersion.cmake"
fi

# Create a simple CMakeLists.txt for the local installation
echo "  Creating local CMakeLists.txt..."
cat > "${TARGET_PATH}/CMakeLists.txt" << 'EOF'
# Local EpochProtos installation
cmake_minimum_required(VERSION 3.20)
project(epoch_protos_local)

# Create an interface library that wraps the prebuilt static library
add_library(epoch_protos_cpp INTERFACE)

# Set the include directories
target_include_directories(epoch_protos_cpp INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}/include
)

# Link to the prebuilt static library
target_link_libraries(epoch_protos_cpp INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}/lib/libepoch_protos_cpp.a
)

# Find and link protobuf dependency
find_package(Protobuf REQUIRED)
target_link_libraries(epoch_protos_cpp INTERFACE protobuf::libprotobuf)

# Add aliases for compatibility
add_library(EpochProtos::epoch_protos_cpp ALIAS epoch_protos_cpp)
add_library(epoch::proto ALIAS epoch_protos_cpp)
EOF

echo "    Created local CMakeLists.txt"

# Summary
echo ""
echo "🎉 Build and copy completed successfully!"
echo "=========================================="
echo "Files copied to: ${TARGET_PATH}"
echo ""
echo "Directory structure:"
echo "  ${TARGET_PATH}/"
echo "  ├── include/epoch_protos/"
echo "  │   └── *.pb.h (generated headers)"
echo "  ├── lib/"
echo "  │   └── libepoch_protos_cpp.a (static library)"
echo "  ├── cmake/EpochProtos/ (if available)"
echo "  │   └── *.cmake (config files)"
echo "  └── CMakeLists.txt (local config)"
echo ""
echo "To use in your project, add to your CMakeLists.txt:"
echo "  add_subdirectory(${TARGET_PATH})"
echo "  target_link_libraries(your_target PRIVATE epoch::proto)"
echo ""
