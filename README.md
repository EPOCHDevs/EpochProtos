# EpochProtos

Protocol Buffer definitions for EpochFolio - generates C++, Python, and TypeScript code.

## Prerequisites

### Required
- **CMake** 3.20+
- **C++ compiler** (g++ or clang++) with C++20 support
- **vcpkg** for protobuf dependency management
- **Python 3.8+** with venv (for Python package)
- **Node.js & npm** (for TypeScript package)

### Python Virtual Environment
The build system automatically creates and uses a virtual environment (`build_venv`) for Python package building and publishing. This isolates dependencies from your system Python.

### Setup vcpkg
```bash
# Clone vcpkg if not already installed
git clone https://github.com/microsoft/vcpkg.git ~/vcpkg
~/vcpkg/bootstrap-vcpkg.sh

# Add to ~/.bashrc
echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.bashrc
echo 'export PATH=$VCPKG_ROOT/installed/x64-linux/tools/protobuf:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install protobuf
cd /path/to/EpochProtos
$VCPKG_ROOT/vcpkg install
```

## Quick Start

### Master Workflow Script (Recommended)

The `master_workflow.sh` script orchestrates all build and deployment tasks:

```bash
# Check all prerequisites
./scripts/master_workflow.sh check-all

# Build all packages (C++, Python, TypeScript)
./scripts/master_workflow.sh build-all

# Test all packages
./scripts/master_workflow.sh test-all

# Install/publish locally
./scripts/master_workflow.sh publish-local

# Copy only C++ files to EpochFolio
./scripts/master_workflow.sh cpp

# Show current status
./scripts/master_workflow.sh status

# Clean all build artifacts
./scripts/master_workflow.sh clean
```

### Individual Workflows

```bash
# Build and copy C++ to EpochDashboard (default target)
./scripts/build_and_copy.sh

# Or specify custom target
./scripts/build_and_copy.sh /path/to/target

# Python workflow
./scripts/master_workflow.sh python build
./scripts/master_workflow.sh python install-local

# TypeScript workflow
./scripts/master_workflow.sh typescript build
./scripts/master_workflow.sh typescript install-local

# Version management
./scripts/master_workflow.sh version get
./scripts/master_workflow.sh version bump patch
./scripts/master_workflow.sh version bump minor
./scripts/master_workflow.sh version bump major
```

### Manual Build

```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
```

## What You Get

- **C++**: Static library in `build/generated/cpp/libepoch_protos_cpp.a`
- **Python**: Package in `build/generated/python/`
- **TypeScript**: Package in `build/generated/typescript/`

## Usage

### C++
```cpp
#include "common.pb.h"
#include "chart_def.pb.h"

epoch_proto::ChartDef chart;
chart.set_id("my_chart");
chart.set_type(epoch_proto::EpochFolioDashboardWidget::Lines);
```

### Python
```python
import common_pb2
import chart_def_pb2

chart = chart_def_pb2.ChartDef()
chart.id = "my_chart"
chart.type = common_pb2.EpochFolioDashboardWidget.Lines
```

### TypeScript
```typescript
import { ChartDef, EpochFolioDashboardWidget } from './chart_def';

const chart = new ChartDef();
chart.setId("my_chart");
chart.setType(EpochFolioDashboardWidget.Lines);
```

## Integration

### C++ Project
```cmake
# After running build_and_copy.sh, your target project will have:
# thirdparty/epoch_protos/
#   ├── include/epoch_protos/  (headers)
#   ├── lib/                    (libepoch_protos_cpp.a)
#   └── CMakeLists.txt

# In your CMakeLists.txt:
add_subdirectory(thirdparty/epoch_protos)
target_link_libraries(your_target PRIVATE epoch::proto)
```

### Python Project
```bash
# Local install
./scripts/master_workflow.sh python install-local

# Or manually
cd build/generated/python
pip install .
```

### TypeScript Project
```bash
# Local install
./scripts/master_workflow.sh typescript install-local

# Or manually
cd build/generated/typescript
npm install
```

## Proto Files

- `common.proto` - Basic types and enums
- `chart_def.proto` - Chart definitions
- `table_def.proto` - Table definitions
- `tearsheet.proto` - Dashboard tearsheet structure

## Publishing

### Test Repositories
```bash
# Publish to TestPyPI and npm dry-run
./scripts/master_workflow.sh publish-test
```

### Production Repositories
```bash
# Publish to PyPI and npm (with version bump prompt)
./scripts/master_workflow.sh publish-prod
```

Environment variables needed:
- `TWINE_USERNAME`, `TWINE_PASSWORD` - PyPI credentials
- `NPM_TOKEN` - npm authentication token

## Testing

```bash
# All tests
./scripts/master_workflow.sh test-all

# Or manually
cd test
g++ -std=c++20 -I../build -o test_cpp test_cpp.cpp ../build/generated/cpp/libepoch_protos_cpp.a -lprotobuf
./test_cpp

python3 test_python.py
```

## Project Structure

```
EpochProtos/
├── proto/                     # Proto source files
│   ├── common.proto
│   ├── chart_def.proto
│   ├── table_def.proto
│   └── tearsheet.proto
├── scripts/                   # Build and deployment scripts
│   ├── master_workflow.sh     # Main orchestration script
│   ├── build_and_copy.sh      # Quick C++ build & copy
│   ├── python_publish.sh      # Python publishing
│   ├── typescript_publish.sh  # TypeScript publishing
│   ├── version_manager.sh     # Version management
│   └── sync_versions.sh       # Sync versions across packages
├── vcpkg.json                 # vcpkg manifest (protobuf dependency)
├── CMakeLists.txt             # CMake configuration
└── README.md
```

## Troubleshooting

### protoc not found
Make sure vcpkg is installed and `VCPKG_ROOT` is set:
```bash
export VCPKG_ROOT=$HOME/vcpkg
export PATH=$VCPKG_ROOT/installed/x64-linux/tools/protobuf:$PATH
$VCPKG_ROOT/vcpkg install
```

### Build fails
```bash
# Clean and rebuild
./scripts/master_workflow.sh clean
./scripts/master_workflow.sh build-all
```

### Check status
```bash
./scripts/master_workflow.sh status
```