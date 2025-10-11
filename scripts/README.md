# EpochProtos Deployment Scripts

Simple scripts for deploying EpochProtos to your local projects.

## Quick Start

### Most Common Use Case (C++ Headers)
```bash
# From EpochProtos root directory
./quick-deploy
```

### Full Deployment Options
```bash
# Deploy everything
./scripts/deploy.sh all

# Deploy just C++ headers
./scripts/deploy.sh cpp

# Deploy just Python package
./scripts/deploy.sh python

# Deploy just npm package
./scripts/deploy.sh npm
```

## Individual Scripts

### C++ Deployment
- **`copy_headers_only.sh`** - Simple copy of headers and static library
- **`copy_to_local.sh`** - Full copy with CMake config files

### Python Deployment
- **`python_publish.sh`** - Full Python package build and publish workflow
  - `./python_publish.sh build` - Build package
  - `./python_publish.sh install-local` - Install locally
  - `./python_publish.sh publish` - Publish to PyPI
- **`copy_python_to_local.sh`** - Copy Python package to EpochAI

### TypeScript/npm Deployment
- **`typescript_publish.sh`** - Full TypeScript package build and publish workflow
  - `./typescript_publish.sh build` - Build package
  - `./typescript_publish.sh install-local` - Install locally
  - `./typescript_publish.sh publish` - Publish to npm

## Target Directories

The scripts automatically copy to these locations:
- **EpochFolio**: `/home/adesola/EpochLab/EpochFolio/thirdparty/epoch_protos/`
- **EpochStratifyX**: `/home/adesola/EpochLab/EpochStratifyX/cpp/thirdparty/epoch_protos/`
- **EpochAI**: `/home/adesola/EpochLab/EpochAI/epoch-protos/`

## Usage Examples

```bash
# Quick C++ deployment (most common)
./quick-deploy

# Full deployment
./scripts/deploy.sh all

# Just build protobuf files
./scripts/deploy.sh build

# Clean build directories
./scripts/deploy.sh clean

# Python package for local development
./scripts/python_publish.sh install-local

# npm package for local testing
./scripts/typescript_publish.sh install-local
```

## Prerequisites

- **C++**: CMake, protobuf compiler
- **Python**: Python 3.8+, pip, build tools
- **TypeScript**: Node.js 16+, npm, protobufjs

All scripts will check prerequisites and provide helpful error messages if anything is missing.

