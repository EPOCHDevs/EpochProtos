# EpochProtos vcpkg Distribution Guide

## Overview

This document describes the complete vcpkg distribution setup for EpochProtos, enabling easy consumption of the protobuf library across C++ projects.

## Files Created for vcpkg Support

### 1. Root Manifest (`vcpkg.json`)
```json
{
  "name": "epoch-protos",
  "version": "1.0.0",
  "dependencies": ["protobuf"],
  "features": {
    "python": { "description": "Enable Python protobuf generation" },
    "typescript": { "description": "Enable TypeScript protobuf generation" },
    "tools": { "description": "Include protobuf compiler and tools" }
  }
}
```

### 2. Port Definition (`ports/epoch-protos/`)
- **`portfile.cmake`**: vcpkg build script
- **`vcpkg.json`**: Port-specific manifest with build dependencies

### 3. Updated CMakeLists.txt Features
- **Build options**: `BUILD_PYTHON_PROTOS`, `BUILD_TYPESCRIPT_PROTOS`, `INSTALL_PROTO_FILES`
- **vcpkg compatibility**: Modern CMake targets, optional dependencies
- **Proper exports**: CMake config files and target exports

### 4. License File (`LICENSE`)
MIT license required for vcpkg distribution.

## Usage Scenarios

### Scenario 1: Direct vcpkg Installation

```bash
# Install from vcpkg registry (when published)
vcpkg install epoch-protos

# Use in project
find_package(EpochProtos CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE EpochProtos::epoch_protos_cpp)
```

### Scenario 2: Local Development with Overlay

```bash
# Install from local port
vcpkg install epoch-protos --overlay-ports=/path/to/EpochProtos/ports

# Build consumer project
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build build
```

### Scenario 3: Manifest Mode (Recommended)

Consumer project structure:
```
my-project/
├── vcpkg.json          # { "dependencies": ["epoch-protos"] }
├── CMakeLists.txt      # find_package(EpochProtos CONFIG REQUIRED)
└── main.cpp           # #include <epoch_protos/common.pb.h>
```

## Build Configurations

### Minimal C++ Only (vcpkg default)
```bash
cmake .. -DBUILD_PYTHON_PROTOS=OFF -DBUILD_TYPESCRIPT_PROTOS=OFF
```

### Full Development Build
```bash
cmake .. -DBUILD_PYTHON_PROTOS=ON -DBUILD_TYPESCRIPT_PROTOS=ON
```

### vcpkg with Tools Feature
```bash
vcpkg install epoch-protos[tools]
```

## Generated Artifacts

When installed via vcpkg, the package provides:

### C++ Library
- **Static library**: `libepoch_protos_cpp.a`
- **Headers**: `include/epoch_protos/*.pb.h`
- **CMake target**: `EpochProtos::epoch_protos_cpp`

### Proto Files (optional)
- **Location**: `share/epoch-protos/proto/*.proto`
- **Usage**: Custom code generation for other languages

### CMake Integration
- **Config file**: `lib/cmake/EpochProtos/EpochProtosConfig.cmake`
- **Targets file**: `lib/cmake/EpochProtos/EpochProtosTargets.cmake`
- **Version file**: `lib/cmake/EpochProtos/EpochProtosConfigVersion.cmake`

## Testing Results

### ✅ Build Tests Passed
- **Minimal build**: C++ library only, no Python/TypeScript
- **Full build**: All language bindings generated
- **vcpkg-style build**: Compatible with vcpkg toolchain

### ✅ Integration Tests Passed
- **Consumer project**: Successfully built and linked
- **CMake targets**: Proper target resolution and linking
- **Header installation**: Correct include paths

### ✅ Runtime Tests Passed
- **C++ example**: All protobuf models work correctly
- **Data serialization**: Protobuf serialization/deserialization functional
- **Enum values**: All enum constants accessible

## Publishing Checklist

To publish to the official vcpkg registry:

1. **✅ Create GitHub release** with tagged version
2. **✅ Update SHA512** in `portfile.cmake` with release archive hash
3. **✅ Test port** with `vcpkg install epoch-protos --overlay-ports=./ports`
4. **✅ Verify examples** work with installed package
5. **⏳ Submit PR** to [Microsoft/vcpkg](https://github.com/Microsoft/vcpkg)

## Distribution Benefits

### For Consumers
- **Easy installation**: Single `vcpkg install` command
- **Dependency management**: Automatic protobuf dependency resolution
- **CMake integration**: Modern target-based linking
- **Cross-platform**: Works on Windows, Linux, macOS

### For Maintainers
- **Automated builds**: vcpkg CI/CD integration
- **Version management**: Semantic versioning support
- **Feature flags**: Optional components (Python, TypeScript, tools)
- **Quality assurance**: vcpkg testing and validation

## Example Consumer Project

See `example_consumer/` directory for a complete working example showing:
- vcpkg manifest configuration
- CMake integration
- Comprehensive usage of all protobuf models
- Portfolio analytics dashboard components

## Supported Platforms

The vcpkg port supports all platforms where protobuf is available:
- **Windows**: Visual Studio 2019+, MinGW
- **Linux**: GCC 9+, Clang 10+
- **macOS**: Xcode 12+

## Version Compatibility

- **CMake**: 3.20+ (C++20 support required)
- **Protobuf**: 3.21.0+ (vcpkg provides compatible version)
- **C++ Standard**: C++20 (for modern features and better type safety)
