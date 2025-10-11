#!/bin/bash

# EpochProtos Python/pip Publishing Script
# This script handles building and publishing Python packages locally and remotely

set -e  # Exit on any error

# Configuration
PACKAGE_NAME="epoch-protos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PYTHON_PKG_DIR="$PROJECT_ROOT/build/generated/python"

# Get version from version manager
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n\r')
else
    VERSION="1.0.0"
fi

# Log the version being used
echo "Using version: $VERSION"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking Python prerequisites..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is not installed"
        exit 1
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        log_error "pip3 is not installed"
        exit 1
    fi
    
    # Check if we're in a virtual environment or if build_venv exists
    if [ -n "$VIRTUAL_ENV" ]; then
        log_info "Using current virtual environment: $VIRTUAL_ENV"
        # Check if build tools are installed
        if ! python -c "import build" 2>/dev/null; then
            log_info "Installing build tools..."
            pip install --upgrade pip
            pip install build twine wheel setuptools
        fi
    else
        # Set up build_venv if it doesn't exist
        if [ ! -d "$PROJECT_ROOT/build_venv" ]; then
            log_info "Creating build_venv virtual environment..."
            python3 -m venv "$PROJECT_ROOT/build_venv"
        fi
        
        # Activate build_venv and install tools
        source "$PROJECT_ROOT/build_venv/bin/activate"
        
        # Check if build tools are installed in venv
        if ! python -c "import build" 2>/dev/null; then
            log_info "Installing build tools in build_venv..."
            pip install --upgrade pip
            pip install build twine wheel setuptools
        fi
    fi
    
    log_success "Python prerequisites check passed"
}

# Function to update template files with current version
update_python_templates() {
    log_info "Updating Python template files with version $VERSION..."
    
    # Update pyproject.toml if it exists in the generated directory
    if [ -f "$PYTHON_PKG_DIR/pyproject.toml" ]; then
        sed -i "s/version = \".*\"/version = \"$VERSION\"/" "$PYTHON_PKG_DIR/pyproject.toml"
    fi
    
    # Update setup.py if it exists in the generated directory
    if [ -f "$PYTHON_PKG_DIR/setup.py" ]; then
        sed -i "s/version=\".*\"/version=\"$VERSION\"/" "$PYTHON_PKG_DIR/setup.py"
    fi
    
    # Update __init__.py if it exists in the package directory
    if [ -f "$PYTHON_PKG_DIR/epoch_protos/__init__.py" ]; then
        sed -i "s/__version__ = \".*\"/__version__ = \"$VERSION\"/" "$PYTHON_PKG_DIR/epoch_protos/__init__.py"
    fi
    
    log_success "Python template files updated to version $VERSION"
}

# Function to generate Python protobuf files
generate_python_protos() {
    # Check if already generated and up to date
    if [ -f "$PROJECT_ROOT/build/.python_generated" ] && [ -d "$PYTHON_PKG_DIR" ]; then
        log_info "Python protos already generated, skipping..."
        update_python_templates
        return 0
    fi

    log_info "Generating Python protobuf files..."

    cd "$PROJECT_ROOT"

    # Create build directory and generate protos
    mkdir -p build
    cd build
    cmake .. -DBUILD_PYTHON_PROTOS=ON -DBUILD_TYPESCRIPT_PROTOS=OFF
    make generate_python_protos setup_python_package

    # Mark as generated
    touch .python_generated

    # Update template files with current version after generation
    update_python_templates

    log_success "Python protobuf files generated"
}

# Function to create Python package structure
create_python_package() {
    log_info "Creating Python package structure..."
    
    # Already set globally now
    # PYTHON_PKG_DIR="$PROJECT_ROOT/build/generated/python"
    
    # Ensure the CMake package structure exists
    if [ ! -d "$PYTHON_PKG_DIR" ] || [ ! -f "$PYTHON_PKG_DIR/setup.py" ]; then
        log_info "CMake Python package not found, generating..."
        cd "$PROJECT_ROOT/build"
        make generate_python_protos setup_python_package
        cd "$PROJECT_ROOT"
    fi
    
    if [ ! -d "$PYTHON_PKG_DIR" ] || [ ! -f "$PYTHON_PKG_DIR/setup.py" ]; then
        log_error "Python package generation failed! Expected at: $PYTHON_PKG_DIR"
        exit 1
    fi
    
    log_info "Using version $VERSION for Python package"
    log_info "✅ Using CMake-generated Python package at $PYTHON_PKG_DIR"
    
    # Update the existing CMake-generated setup.py with our version
    sed -i "s/version=\"[^\"]*\"/version=\"$VERSION\"/" "$PYTHON_PKG_DIR/setup.py"
    
    log_success "Python package structure ready at $PYTHON_PKG_DIR"
    return 0
    
    # Backup: if CMake setup.py is incomplete, create our own
    cat > "$PYTHON_PKG_DIR/setup.py" << EOF
import os
from setuptools import setup, find_packages

# Read README for long description
def read_readme():
    readme_path = os.path.join(os.path.dirname(__file__), '..', 'README.md')
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            return f.read()
    return "Protocol Buffer definitions for EpochFolio models"

setup(
    name="$PACKAGE_NAME",
    version="$VERSION",
    description="Protocol Buffer definitions for EpochFolio models, generating C++, TypeScript, and Python code",
    long_description=read_readme(),
    long_description_content_type="text/markdown",
    author="EpochLab",
    author_email="dev@epochlab.ai",
    url="https://github.com/epochlab/epoch-protos",
    project_urls={
        "Bug Reports": "https://github.com/epochlab/epoch-protos/issues",
        "Source": "https://github.com/epochlab/epoch-protos",
        "Documentation": "https://github.com/epochlab/epoch-protos#readme",
    },
    packages=find_packages(),
    install_requires=[
        "protobuf>=3.21.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=22.0.0",
            "mypy>=1.0.0",
        ],
        "pydantic": [
            "pydantic>=2.0.0",
            "typing-extensions>=4.0.0",
        ]
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Office/Business :: Financial",
        "Topic :: Software Development :: Code Generators",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    include_package_data=True,
    package_data={
        "": ["*.proto", "*.py", "*.pyi"],
    },
    keywords="protobuf, protocol-buffers, epochfolio, financial, portfolio, analytics, grpc",
    zip_safe=False,
)
EOF

    # Create MANIFEST.in
    cat > "$PYTHON_PKG_DIR/MANIFEST.in" << EOF
include README.md
include LICENSE
include *.proto
recursive-include * *.proto
recursive-include * *.pyi
global-exclude *.pyc
global-exclude __pycache__
EOF

    # Copy essential files
    cp "$PROJECT_ROOT/README.md" "$PYTHON_PKG_DIR/" 2>/dev/null || true
    cp "$PROJECT_ROOT/LICENSE" "$PYTHON_PKG_DIR/" 2>/dev/null || true
    
    # Copy proto files
    mkdir -p "$PYTHON_PKG_DIR/proto"
    cp "$PROJECT_ROOT/proto/"*.proto "$PYTHON_PKG_DIR/proto/" 2>/dev/null || true
    
    log_success "Python package structure created in $PYTHON_PKG_DIR"
}

# Function to build Python package
build_python_package() {
    # Check if already built with correct version
    if [ -f "$PYTHON_PKG_DIR/.built_version" ]; then
        BUILT_VERSION=$(cat "$PYTHON_PKG_DIR/.built_version")
        if [ "$BUILT_VERSION" = "$VERSION" ] && [ -d "$PYTHON_PKG_DIR/dist" ]; then
            log_info "Python package already built for version $VERSION, skipping..."
            return 0
        fi
    fi

    log_info "Building Python package with version $VERSION..."

    # Ensure we're in a virtual environment
    if [ -z "$VIRTUAL_ENV" ]; then
        if [ -d "$PROJECT_ROOT/build_venv" ]; then
            source "$PROJECT_ROOT/build_venv/bin/activate"
        else
            log_error "No virtual environment active. Please activate build_venv or run with appropriate environment"
            exit 1
        fi
    fi

    cd "$PYTHON_PKG_DIR"

    # Clean previous builds thoroughly
    rm -rf build/ dist/ *.egg-info/
    rm -rf ../*.egg-info/
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true

    # Verify the setup.py has correct version
    if grep -q "version=\"$VERSION\"" setup.py; then
        log_info "✅ setup.py contains correct version: $VERSION"
    else
        log_error "❌ setup.py version mismatch!"
        grep "version=" setup.py
        exit 1
    fi

    # Build package using the venv's python
    python -m build

    # Mark build version
    echo "$VERSION" > .built_version

    log_success "Python package built successfully"
    ls -la dist/
}

# Function to test Python package locally
test_python_package_local() {
    log_info "Testing Python package locally..."
    
    cd "$PYTHON_PKG_DIR"
    
    # Create virtual environment for testing
    rm -rf test_venv
    python3 -m venv test_venv
    source test_venv/bin/activate
    
    # Install the package - find the actual wheel file
    WHEEL_FILE=$(ls dist/*.whl 2>/dev/null | head -n1)
    if [ -z "$WHEEL_FILE" ]; then
        log_error "No wheel file found in dist/"
        return 1
    fi
    pip install "$WHEEL_FILE"
    
    # Test import and basic functionality
    python3 -c "
import epoch_protos.common_pb2 as common
import epoch_protos.chart_def_pb2 as chart_def
import epoch_protos.table_def_pb2 as table_def

print('Testing Python protobuf package...')

# Test Scalar
scalar = common.Scalar()
scalar.decimal_value = 42.5
print(f'Scalar value: {scalar.decimal_value}')

# Test ChartDef
chart = chart_def.ChartDef()
chart.id = 'test_chart'
chart.title = 'Test Chart'
chart.type = common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetLines'].number
print(f'Chart: {chart.title}')

# Test Table
table = table_def.Table()
table.title = 'Test Table'
table.type = common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetDataTable'].number
print(f'Table: {table.title}')

print('✅ Python package test successful!')
"
    
    # Deactivate and cleanup
    deactivate
    rm -rf test_venv
    
    log_success "Python package local test passed"
}

# Function to publish to local pip repository (for testing)
publish_python_local() {
    log_info "Publishing Python package locally..."
    
    cd "$PYTHON_PKG_DIR"
    
    # Install locally in development mode
    pip install -e .
    
    log_success "Python package installed locally in development mode"
    log_info "You can now import epoch_protos in Python"
}

# Function to publish to PyPI Test
publish_python_test_pypi() {
    log_info "Publishing to PyPI Test..."

    # Ensure we're in a virtual environment
    if [ -z "$VIRTUAL_ENV" ]; then
        if [ -d "$PROJECT_ROOT/build_venv" ]; then
            source "$PROJECT_ROOT/build_venv/bin/activate"
        else
            log_error "No virtual environment active. Please run check command first."
            exit 1
        fi
    fi

    cd "$PYTHON_PKG_DIR"
    
    # Check if credentials are available (either via env vars or .pypirc)
    if [ -z "$TWINE_PASSWORD" ] && [ -z "$TWINE_USERNAME" ]; then
        if [ ! -f "$HOME/.pypirc" ]; then
            log_warning "PyPI credentials not set. Please set TWINE_USERNAME and TWINE_PASSWORD or configure ~/.pypirc"
            log_info "For API tokens, use: TWINE_USERNAME=__token__ TWINE_PASSWORD=pypi-..."
            log_info "Skipping PyPI Test upload"
            return
        else
            log_info "Using credentials from ~/.pypirc"
        fi
    fi
    
    # Upload to Test PyPI (use venv python)
    python -m twine upload --repository testpypi dist/*
    
    log_success "Package uploaded to PyPI Test"
    log_info "Install with: pip install -i https://test.pypi.org/simple/ $PACKAGE_NAME"
}

# Function to publish to PyPI
publish_python_pypi() {
    log_info "Publishing to PyPI..."

    # Ensure we're in a virtual environment
    if [ -z "$VIRTUAL_ENV" ]; then
        if [ -d "$PROJECT_ROOT/build_venv" ]; then
            source "$PROJECT_ROOT/build_venv/bin/activate"
        else
            log_error "No virtual environment active. Please run check command first."
            exit 1
        fi
    fi

    cd "$PYTHON_PKG_DIR"
    
    # Check if credentials are available (either via env vars or .pypirc)
    if [ -z "$TWINE_PASSWORD" ] && [ -z "$TWINE_USERNAME" ]; then
        if [ ! -f "$HOME/.pypirc" ]; then
            log_error "PyPI credentials not set. Please set TWINE_USERNAME and TWINE_PASSWORD or configure ~/.pypirc"
            log_info "For API tokens, use: TWINE_USERNAME=__token__ TWINE_PASSWORD=pypi-..."
            exit 1
        else
            log_info "Using credentials from ~/.pypirc"
        fi
    fi
    
    # Upload to PyPI (use venv python)
    python -m twine upload dist/*
    
    log_success "Package uploaded to PyPI"
    log_info "Install with: pip install $PACKAGE_NAME"
}

# Function to create test script
create_python_test_script() {
    log_info "Creating Python test script..."
    
    cat > "$PROJECT_ROOT/test_python_package.py" << 'EOF'
#!/usr/bin/env python3
"""
Test script for the epoch-protos Python package
"""

def test_imports():
    """Test that all modules can be imported"""
    try:
        import epoch_protos.common_pb2 as common
        import epoch_protos.chart_def_pb2 as chart_def
        import epoch_protos.table_def_pb2 as table_def
        print("✅ All imports successful")
        return True
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False

def test_basic_functionality():
    """Test basic protobuf functionality"""
    try:
        import epoch_protos.common_pb2 as common
        import epoch_protos.chart_def_pb2 as chart_def
        
        # Test scalar
        scalar = common.Scalar()
        scalar.decimal_value = 123.45
        assert scalar.decimal_value == 123.45
        
        # Test chart
        chart = chart_def.ChartDef()
        chart.id = "test"
        chart.title = "Test Chart"
        chart.type = common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetBar'].number
        assert chart.id == "test"
        assert chart.title == "Test Chart"
        
        # Test serialization
        data = chart.SerializeToString()
        chart2 = chart_def.ChartDef()
        chart2.ParseFromString(data)
        assert chart2.id == chart.id
        assert chart2.title == chart.title
        
        print("✅ Basic functionality test passed")
        return True
    except Exception as e:
        print(f"❌ Functionality test failed: {e}")
        return False

def test_enums():
    """Test enum values"""
    try:
        import epoch_protos.common_pb2 as common
        
        # Test widget enum
        assert common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetLines'].number == 2
        assert common._EPOCHFOLIODASHBOARDWIDGET.values_by_name['WidgetBar'].number == 3
        
        print("✅ Enum test passed")
        return True
    except Exception as e:
        print(f"❌ Enum test failed: {e}")
        return False

if __name__ == "__main__":
    print("Testing epoch-protos Python package...")
    
    tests = [test_imports, test_basic_functionality, test_enums]
    passed = 0
    
    for test in tests:
        if test():
            passed += 1
    
    print(f"\nResults: {passed}/{len(tests)} tests passed")
    
    if passed == len(tests):
        print("🎉 All tests passed!")
        exit(0)
    else:
        print("💥 Some tests failed!")
        exit(1)
EOF

    chmod +x "$PROJECT_ROOT/test_python_package.py"
    log_success "Python test script created: test_python_package.py"
}

# Main workflow function
run_python_workflow() {
    local command="${1:-all}"
    
    case $command in
        "check")
            check_prerequisites
            ;;
        "generate")
            check_prerequisites
            generate_python_protos
            ;;
        "package")
            check_prerequisites
            generate_python_protos
            create_python_package
            ;;
        "build")
            check_prerequisites
            generate_python_protos
            create_python_package
            build_python_package
            ;;
        "test")
            check_prerequisites
            generate_python_protos
            create_python_package
            build_python_package
            test_python_package_local
            ;;
        "install-local")
            check_prerequisites
            generate_python_protos
            create_python_package
            publish_python_local
            ;;
        "publish-test")
            check_prerequisites
            generate_python_protos
            create_python_package
            build_python_package
            test_python_package_local
            publish_python_test_pypi
            ;;
        "publish")
            check_prerequisites
            # Reuse existing builds if available
            if [ ! -f "$PYTHON_PKG_DIR/.built_version" ] || [ "$(cat "$PYTHON_PKG_DIR/.built_version")" != "$VERSION" ]; then
                generate_python_protos
                create_python_package
                build_python_package
                test_python_package_local
            else
                log_info "Reusing existing build artifacts for version $VERSION"
            fi
            publish_python_pypi
            ;;
        "create-test")
            create_python_test_script
            ;;
        "all")
            check_prerequisites
            generate_python_protos
            create_python_package
            build_python_package
            test_python_package_local
            create_python_test_script
            ;;
        *)
            echo "Usage: $0 [check|generate|package|build|test|install-local|publish-test|publish|create-test|all]"
            echo ""
            echo "Commands:"
            echo "  check         - Check prerequisites"
            echo "  generate      - Generate Python protobuf files"
            echo "  package       - Create Python package structure"
            echo "  build         - Build Python package"
            echo "  test          - Test Python package locally"
            echo "  install-local - Install package locally for development"
            echo "  publish-test  - Publish to PyPI Test"
            echo "  publish       - Publish to PyPI"
            echo "  create-test   - Create test script"
            echo "  all           - Run all steps except publishing (default)"
            exit 1
            ;;
    esac
}

# Run the workflow
run_python_workflow "$@"
