#!/bin/bash

# EpochProtos Master Workflow Script
# This script orchestrates the complete distribution workflow for C++ (direct copy), Python/pip, and TypeScript/npm
# Note: vcpkg is used for dependency management (protobuf versions), not for distribution

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Set up vcpkg environment
export VCPKG_ROOT="${VCPKG_ROOT:-$HOME/vcpkg}"
export PATH="$VCPKG_ROOT/installed/x64-linux/tools/protobuf:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_section() {
    echo -e "\n${PURPLE}=== $1 ===${NC}\n"
}

# Function to show usage
show_usage() {
    cat << EOF
EpochProtos Master Workflow Script

Usage: $0 <command> [options]

Commands:
  check-all         - Check all prerequisites (C++, Python, TypeScript)
  build-all         - Build all packages (C++, Python, TypeScript)
  test-all          - Test all packages locally
  publish-local     - Install/publish all packages locally
  publish-test      - Publish to test repositories (TestPyPI, npm dry-run)
  publish-prod      - Publish to production repositories (PyPI, npm)
  
  cpp               - Copy C++ headers and libraries to EpochFolio
  python <args>     - Run Python workflow with arguments  
  typescript <args> - Run TypeScript workflow with arguments
  
  version <cmd>     - Version management (get, set, bump, release)
  clean             - Clean all build artifacts
  status            - Show current status of all packages

Examples:
  $0 check-all                    # Check all prerequisites
  $0 build-all                    # Build all packages
  $0 test-all                     # Test all packages
  $0 publish-local                # Install all packages locally
  $0 cpp                          # Copy C++ files to EpochFolio
  $0 python build                 # Build only Python package
  $0 typescript publish          # Publish only TypeScript to npm
  $0 version bump patch           # Bump patch version
  $0 version release minor        # Release with minor version bump

Environment Variables:
  TWINE_USERNAME, TWINE_PASSWORD  # PyPI credentials (for Python publishing)
  NPM_TOKEN                       # npm token (for TypeScript publishing)

EOF
}

# Function to check if a script exists and is executable
check_script() {
    local script="$1"
    if [ ! -f "$script" ]; then
        log_error "Script not found: $script"
        return 1
    fi
    if [ ! -x "$script" ]; then
        chmod +x "$script"
    fi
    return 0
}

# Function to run a workflow script
run_workflow() {
    local workflow="$1"
    shift
    local script="$SCRIPT_DIR/${workflow}_workflow.sh"
    
    if [ "$workflow" = "python" ]; then
        script="$SCRIPT_DIR/python_publish.sh"
    elif [ "$workflow" = "typescript" ]; then
        script="$SCRIPT_DIR/typescript_publish.sh"
    fi
    
    if ! check_script "$script"; then
        return 1
    fi
    
    log_section "Running $workflow workflow: $*"
    "$script" "$@"
}

# Function to check all prerequisites
check_all_prerequisites() {
    log_section "Checking All Prerequisites"
    
    local failed=0
    
    # Check C++ tools (cmake, protoc, compiler)
    log_info "Checking C++ prerequisites..."
    if check_cpp_prerequisites; then
        log_success "C++ prerequisites OK"
    else
        log_error "C++ prerequisites failed"
        failed=1
    fi
    
    # Check Python
    log_info "Checking Python prerequisites..."
    if run_workflow python check; then
        log_success "Python prerequisites OK"
    else
        log_error "Python prerequisites failed"
        failed=1
    fi
    
    # Check TypeScript
    log_info "Checking TypeScript prerequisites..."
    if run_workflow typescript check; then
        log_success "TypeScript prerequisites OK"
    else
        log_error "TypeScript prerequisites failed"
        failed=1
    fi
    
    if [ $failed -eq 0 ]; then
        log_success "All prerequisites check passed!"
    else
        log_error "Some prerequisites checks failed"
        exit 1
    fi
}

# Function to check C++ prerequisites
check_cpp_prerequisites() {
    local failed=0
    
    # Check cmake
    if ! command -v cmake &> /dev/null; then
        log_error "cmake is not installed"
        failed=1
    fi
    
    # Check protoc
    if ! command -v protoc &> /dev/null; then
        log_error "protoc is not installed"
        failed=1
    fi
    
    # Check C++ compiler
    if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
        log_error "No C++ compiler found (g++ or clang++)"
        failed=1
    fi
    
    # Check vcpkg for dependency management
    if [ -n "$VCPKG_ROOT" ] && [ -d "$VCPKG_ROOT" ]; then
        log_info "vcpkg found at $VCPKG_ROOT (for dependency management)"
    elif [ -d "$HOME/vcpkg" ]; then
        log_info "vcpkg found at $HOME/vcpkg (for dependency management)"
    else
        log_warning "vcpkg not found - will use system protobuf packages"
        log_info "For consistent versions, consider installing vcpkg"
    fi
    
    # Check if target directories exist
    local epochdashboard_dir="/home/adesola/EpochLab/EpochDashboard"
    local epochfolio_dir="/home/adesola/EpochLab/EpochFolio"

    if [ -d "$epochdashboard_dir" ]; then
        log_info "EpochDashboard directory found at $epochdashboard_dir"
    else
        log_warning "EpochDashboard directory not found at $epochdashboard_dir"
    fi

    if [ -d "$epochfolio_dir" ]; then
        log_info "EpochFolio directory found at $epochfolio_dir"
    else
        log_warning "EpochFolio directory not found at $epochfolio_dir"
    fi
    
    return $failed
}

# Function to build C++ files (called once)
build_cpp_protos() {
    if [ -f "$PROJECT_ROOT/build/.cpp_built" ]; then
        log_info "C++ protos already built, skipping..."
        return 0
    fi

    log_info "Building C++ protobuf files..."
    cd "$PROJECT_ROOT"
    mkdir -p build
    cd build
    cmake .. -DBUILD_PYTHON_PROTOS=OFF -DBUILD_TYPESCRIPT_PROTOS=OFF
    make -j$(nproc)
    touch .cpp_built
    cd "$PROJECT_ROOT"
    log_success "C++ protobuf files built"
}

# Function to copy C++ files to both EpochFolio and EpochDashboard
# DEPRECATED: This function is deprecated as of EpochProtos v2.0.8+
# Projects should use CMake FetchContent instead to avoid ABI mismatches
copy_cpp_files() {
    log_section "Copying C++ Files to EpochFolio and EpochDashboard"
    log_warning "DEPRECATED: C++ file copying is deprecated. Use FetchContent instead."
    log_info "See build_and_copy.sh for recommended FetchContent usage."

    local epochfolio_dir="/home/adesola/EpochLab/EpochFolio/thirdparty/epoch_protos"
    local epochdashboard_dir="/home/adesola/EpochLab/EpochDashboard/cpp/thirdparty/epoch_protos"

    # Ensure C++ is built first
    build_cpp_protos

    # Copy to EpochDashboard first (this is the primary target)
    if [ -f "$PROJECT_ROOT/scripts/build_and_copy.sh" ]; then
        log_info "Copying to EpochDashboard using build_and_copy.sh..."
        "$PROJECT_ROOT/scripts/build_and_copy.sh" "$epochdashboard_dir"
    else
        log_warning "build_and_copy.sh not found, copying manually to EpochDashboard..."
        if [ -d "$(dirname "$epochdashboard_dir")" ]; then
            mkdir -p "$epochdashboard_dir/include/epoch_protos" "$epochdashboard_dir/lib"
            # Copy only our proto files (not WKT)
            for proto_file in common chart_def table_def tearsheet; do
                [ -f "$PROJECT_ROOT/build/${proto_file}.pb.h" ] && cp "$PROJECT_ROOT/build/${proto_file}.pb.h" "$epochdashboard_dir/include/epoch_protos/" 2>/dev/null || true
            done
            cp "$PROJECT_ROOT/build/libepoch_protos_cpp.a" "$epochdashboard_dir/lib/" 2>/dev/null || true
            log_info "Manual copy to EpochDashboard completed"
        else
            log_warning "EpochDashboard directory $(dirname "$epochdashboard_dir") does not exist"
        fi
    fi

    # Also copy to EpochFolio if it exists
    if [ -d "$(dirname "$epochfolio_dir")" ]; then
        log_info "Copying to EpochFolio..."
        mkdir -p "$epochfolio_dir/include/epoch_protos" "$epochfolio_dir/lib"
        # Copy only our proto files (not WKT)
        for proto_file in common chart_def table_def tearsheet; do
            [ -f "$PROJECT_ROOT/build/${proto_file}.pb.h" ] && cp "$PROJECT_ROOT/build/${proto_file}.pb.h" "$epochfolio_dir/include/epoch_protos/" 2>/dev/null || true
        done
        cp "$PROJECT_ROOT/build/libepoch_protos_cpp.a" "$epochfolio_dir/lib/" 2>/dev/null || true
        log_info "Copy to EpochFolio completed"
    else
        log_info "EpochFolio directory not found, skipping"
    fi

    log_success "C++ files copied to target projects"
}

# Function to build all packages
build_all_packages() {
    log_section "Building All Packages"

    # Build C++ files once
    build_cpp_protos

    # Build Python package (will reuse C++ build artifacts)
    log_info "Building Python package..."
    run_workflow python build

    # Build TypeScript package
    log_info "Building TypeScript package..."
    run_workflow typescript build

    log_success "All packages built successfully!"
}

# Function to test all packages
test_all_packages() {
    log_section "Testing All Packages"
    
    # Test C++ (check if files were copied correctly)
    log_info "Testing C++ package..."
    local epochfolio_dir="/home/adesola/EpochLab/EpochFolio/thirdparty/epoch_protos"
    if [ -d "$epochfolio_dir/include" ] && [ -d "$epochfolio_dir/lib" ]; then
        log_success "C++ files found in EpochFolio"
    else
        log_warning "C++ files not found in expected location"
    fi
    
    # Test Python
    log_info "Testing Python package..."
    run_workflow python test
    
    # Test TypeScript
    log_info "Testing TypeScript package..."
    run_workflow typescript test
    
    log_success "All packages tested successfully!"
}

# Function to publish all packages locally
publish_all_local() {
    log_section "Publishing All Packages Locally"
    
    # Copy C++ files to EpochFolio
    log_info "Copying C++ files to EpochFolio..."
    copy_cpp_files
    
    # Install Python locally
    log_info "Installing Python package locally..."
    run_workflow python install-local
    
    # Install TypeScript locally
    log_info "Installing TypeScript package locally..."
    run_workflow typescript install-local
    
    log_success "All packages installed locally!"
}

# Function to publish to test repositories
publish_all_test() {
    log_section "Publishing to Test Repositories"
    
    # Copy C++ files (no test needed, direct copy)
    log_info "Copying C++ files to EpochFolio..."
    copy_cpp_files
    
    # Publish Python to TestPyPI
    log_info "Publishing Python to TestPyPI..."
    run_workflow python publish-test
    
    # Run TypeScript dry-run
    log_info "Running TypeScript npm dry-run..."
    run_workflow typescript dry-run
    
    log_success "Test publishing completed!"
}

# Function to publish to production repositories
publish_all_production() {
    log_section "Publishing to Production Repositories"

    log_warning "This will publish to production repositories!"
    log_warning "Make sure you have:"
    log_warning "1. Tested all packages thoroughly"
    log_warning "2. Set up proper credentials (PyPI, npm)"
    log_warning "3. EpochFolio is ready for C++ file updates"

    # Force clean regeneration for production
    log_info "Clearing build cache to force fresh generation..."
    rm -f "$PROJECT_ROOT/build/.typescript_generated"
    rm -f "$PROJECT_ROOT/build/.python_generated"
    rm -f "$PROJECT_ROOT/build/.cpp_built"
    rm -f "$PROJECT_ROOT/typescript_package/.built_version"
    
    # Ask about version bump
    echo -e "${YELLOW}Version Management:${NC}"
    current_version=$("$SCRIPT_DIR/version_manager.sh" get)
    echo "Current version: $current_version"
    echo ""
    echo "Choose version bump type:"
    echo "1) Patch (bug fixes) - ${current_version} -> $(echo $current_version | awk -F. '{print $1"."$2"."($3+1)}')"
    echo "2) Minor (new features) - ${current_version} -> $(echo $current_version | awk -F. '{print $1"."($2+1)".0"}')"  
    echo "3) Major (breaking changes) - ${current_version} -> $(echo $current_version | awk -F. '{print ($1+1)".0.0"}')"
    echo "4) No version bump (use current)"
    echo ""
    read -p "Select option (1-4): " -n 1 -r version_choice
    echo
    
    case $version_choice in
        1)
            log_info "Bumping patch version..."
            "$SCRIPT_DIR/version_manager.sh" bump patch
            "$SCRIPT_DIR/version_manager.sh" update
            ;;
        2)
            log_info "Bumping minor version..."
            "$SCRIPT_DIR/version_manager.sh" bump minor
            "$SCRIPT_DIR/version_manager.sh" update
            ;;
        3)
            log_info "Bumping major version..."
            "$SCRIPT_DIR/version_manager.sh" bump major
            "$SCRIPT_DIR/version_manager.sh" update
            ;;
        4)
            log_info "Using current version: $current_version"
            ;;
        *)
            log_error "Invalid selection"
            return 1
            ;;
    esac
    
    new_version=$("$SCRIPT_DIR/version_manager.sh" get)
    
    read -p "Continue with production publishing version $new_version? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Production publishing cancelled"
        return 0
    fi
    
    # Copy C++ files to EpochFolio
    log_info "Copying C++ files to EpochFolio..."
    copy_cpp_files
    
    # Publish Python to PyPI
    log_info "Publishing Python to PyPI..."
    run_workflow python publish
    
    # Publish TypeScript to npm
    log_info "Publishing TypeScript to npm..."
    run_workflow typescript publish
    
    # Create git tag for the version
    log_info "Creating git tag for version $new_version..."
    "$SCRIPT_DIR/version_manager.sh" tag
    
    log_success "Production publishing completed!"
    log_info "✅ C++ files copied to EpochFolio"
    log_info "✅ Python package published to PyPI" 
    log_info "✅ TypeScript package published to npm"
    log_info "Don't forget to push the git tag: git push origin v$new_version"
}

# Function to clean build artifacts
clean_all() {
    log_section "Cleaning Build Artifacts"

    cd "$PROJECT_ROOT"

    # Clean common build directories
    rm -rf build/
    rm -rf python_package/
    rm -rf typescript_package/
    rm -rf test_typescript_app/
    rm -rf build_venv/

    # Clean archives
    rm -f *.tar.gz *.sha512

    # Clean Python artifacts
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.egg-info" -type d -exec rm -rf {} + 2>/dev/null || true

    # Clean TypeScript artifacts
    find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.tgz" -delete 2>/dev/null || true

    log_success "All build artifacts cleaned!"
}

# Function to show current status
show_status() {
    log_section "Current Status"
    
    cd "$PROJECT_ROOT"
    
    # Git status
    log_info "Git Status:"
    git status --short || log_warning "Not a git repository"
    
    # Check if archives exist
    log_info "Release Archives:"
    ls -la *.tar.gz *.sha512 2>/dev/null || log_info "No archives found"
    
    # Check build directories
    log_info "Build Directories:"
    [ -d "build/" ] && echo "✅ build/" || echo "❌ build/"
    [ -d "python_package/" ] && echo "✅ python_package/" || echo "❌ python_package/"
    [ -d "typescript_package/" ] && echo "✅ typescript_package/" || echo "❌ typescript_package/"
    
    # Check prerequisites
    log_info "Prerequisites:"
    command -v git &>/dev/null && echo "✅ git" || echo "❌ git"
    command -v cmake &>/dev/null && echo "✅ cmake" || echo "❌ cmake"
    command -v protoc &>/dev/null && echo "✅ protoc" || echo "❌ protoc"
    command -v g++ &>/dev/null && echo "✅ g++" || echo "❌ g++"
    command -v python3 &>/dev/null && echo "✅ python3" || echo "❌ python3"
    command -v node &>/dev/null && echo "✅ node" || echo "❌ node"
    command -v npm &>/dev/null && echo "✅ npm" || echo "❌ npm"
    
    # Check vcpkg for dependency management
    if [ -n "$VCPKG_ROOT" ] && [ -d "$VCPKG_ROOT" ]; then
        echo "✅ vcpkg (dependency mgmt)"
    elif [ -d "$HOME/vcpkg" ]; then
        echo "✅ vcpkg (dependency mgmt)"
    else
        echo "⚠️  vcpkg (dependency mgmt)"
    fi
    
    # Check target directories
    if [ -d "/home/adesola/EpochLab/EpochDashboard" ]; then
        echo "✅ EpochDashboard directory"
    else
        echo "❌ EpochDashboard directory"
    fi
    if [ -d "/home/adesola/EpochLab/EpochFolio" ]; then
        echo "✅ EpochFolio directory"
    else
        echo "❌ EpochFolio directory"
    fi
}


# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Main command handling
case "${1:-help}" in
    "check-all")
        check_all_prerequisites
        ;;
    "build-all")
        check_all_prerequisites
        build_all_packages
        ;;
    "test-all")
        check_all_prerequisites
        build_all_packages
        test_all_packages
        ;;
    "publish-local")
        check_all_prerequisites
        build_all_packages
        test_all_packages
        publish_all_local
        ;;
    "publish-test")
        check_all_prerequisites
        build_all_packages
        test_all_packages
        publish_all_test
        ;;
    "publish-prod")
        check_all_prerequisites
        build_all_packages
        test_all_packages
        publish_all_production
        ;;
    "cpp")
        copy_cpp_files
        ;;
    "python")
        shift
        run_workflow python "$@"
        ;;
    "typescript")
        shift
        run_workflow typescript "$@"
        ;;
    "version")
        shift
        "$SCRIPT_DIR/version_manager.sh" "$@"
        ;;
    "clean")
        clean_all
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        exit 1
        ;;
esac

log_success "Master workflow completed successfully!"
