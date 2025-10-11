#!/bin/bash

# Script to synchronize version across all configuration files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get version from VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n\r')
else
    echo "ERROR: VERSION file not found!"
    exit 1
fi

echo "Syncing version $VERSION across all files..."

# Update Python template files
if [ -f "$PROJECT_ROOT/python/setup.py" ]; then
    sed -i "s/version=\".*\"/version=\"$VERSION\"/" "$PROJECT_ROOT/python/setup.py"
    echo "✅ Updated python/setup.py"
fi

if [ -f "$PROJECT_ROOT/python/pyproject.toml" ]; then
    sed -i "s/version = \".*\"/version = \"$VERSION\"/" "$PROJECT_ROOT/python/pyproject.toml"
    echo "✅ Updated python/pyproject.toml"
fi

if [ -f "$PROJECT_ROOT/python/__init__.py" ]; then
    sed -i "s/__version__ = \".*\"/__version__ = \"$VERSION\"/" "$PROJECT_ROOT/python/__init__.py"
    echo "✅ Updated python/__init__.py"
fi

# Update TypeScript template files
if [ -f "$PROJECT_ROOT/typescript/package.json" ]; then
    sed -i "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" "$PROJECT_ROOT/typescript/package.json"
    echo "✅ Updated typescript/package.json"
fi

# Update CMakeLists.txt
if [ -f "$PROJECT_ROOT/CMakeLists.txt" ]; then
    sed -i "s/project(EpochProtos VERSION .*/project(EpochProtos VERSION $VERSION LANGUAGES CXX)/" "$PROJECT_ROOT/CMakeLists.txt"
    echo "✅ Updated CMakeLists.txt"
fi

# Update vcpkg.json if it exists
if [ -f "$PROJECT_ROOT/vcpkg.json" ]; then
    sed -i "s/\"version-string\": \".*\"/\"version-string\": \"$VERSION\"/" "$PROJECT_ROOT/vcpkg.json"
    echo "✅ Updated vcpkg.json"
fi

echo ""
echo "Version $VERSION synchronized across all configuration files!"
echo ""
echo "Files updated:"
echo "  - Python: setup.py, pyproject.toml, __init__.py"
echo "  - TypeScript: package.json (if exists)"
echo "  - CMake: CMakeLists.txt"
echo "  - vcpkg: vcpkg.json (if exists)"