#!/bin/bash

# EpochProtos Version Manager
# Centralized version management for all packages (vcpkg, Python, TypeScript)

set -e

# Configuration
VERSION_FILE="VERSION"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# Function to get current version
get_current_version() {
    if [ -f "$PROJECT_ROOT/$VERSION_FILE" ]; then
        cat "$PROJECT_ROOT/$VERSION_FILE"
    else
        echo "1.0.0"
    fi
}

# Function to set version
set_version() {
    local new_version="$1"
    
    if [ -z "$new_version" ]; then
        log_error "Version cannot be empty"
        return 1
    fi
    
    # Validate semantic version format
    if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Version must be in semantic format (x.y.z)"
        return 1
    fi
    
    echo "$new_version" > "$PROJECT_ROOT/$VERSION_FILE"
    log_success "Version set to $new_version"
}

# Function to bump version
bump_version() {
    local bump_type="${1:-patch}"
    local current_version=$(get_current_version)
    
    # Parse current version
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Bump version based on type
    case $bump_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            log_error "Invalid bump type. Use: major, minor, or patch"
            return 1
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    set_version "$new_version"
    echo "$new_version"
}

# Function to update all package files with new version
update_all_versions() {
    local version=$(get_current_version)
    
    log_info "Updating all package files to version $version..."
    
    # Use sync_versions.sh script if it exists
    if [ -f "$SCRIPT_DIR/sync_versions.sh" ]; then
        log_info "Using sync_versions.sh to update all files..."
        "$SCRIPT_DIR/sync_versions.sh"
        
        # Also update generated files if they exist
        if [ -f "$PROJECT_ROOT/build/generated/python/epoch_protos/__init__.py" ]; then
            sed -i "s/__version__ = \"[^\"]*\"/__version__ = \"$version\"/" "$PROJECT_ROOT/build/generated/python/epoch_protos/__init__.py"
            log_info "Updated build/generated/python/epoch_protos/__init__.py"
        fi
        
        if [ -f "$PROJECT_ROOT/build/generated/python/setup.py" ]; then
            sed -i "s/version=\"[^\"]*\"/version=\"$version\"/" "$PROJECT_ROOT/build/generated/python/setup.py"
            log_info "Updated build/generated/python/setup.py"
        fi
        
        if [ -f "$PROJECT_ROOT/build/generated/python/pyproject.toml" ]; then
            sed -i "s/version = \"[^\"]*\"/version = \"$version\"/" "$PROJECT_ROOT/build/generated/python/pyproject.toml"
            log_info "Updated build/generated/python/pyproject.toml"
        fi
    else
        # Fallback to manual updates
        # Update vcpkg.json (for dependency version consistency)
        if [ -f "$PROJECT_ROOT/vcpkg.json" ]; then
            sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$version\"/" "$PROJECT_ROOT/vcpkg.json"
            log_info "Updated vcpkg.json"
        fi
        
        # Update Python setup.py
        if [ -f "$PROJECT_ROOT/python/setup.py" ]; then
            sed -i "s/version=\"[^\"]*\"/version=\"$version\"/" "$PROJECT_ROOT/python/setup.py"
            log_info "Updated python/setup.py"
        fi
        
        # Update CMakeLists.txt if it has version
        if [ -f "$PROJECT_ROOT/CMakeLists.txt" ]; then
            if grep -q "VERSION " "$PROJECT_ROOT/CMakeLists.txt"; then
                sed -i "s/VERSION [0-9]\+\.[0-9]\+\.[0-9]\+/VERSION $version/" "$PROJECT_ROOT/CMakeLists.txt"
                log_info "Updated CMakeLists.txt"
            fi
        fi
    fi
    
    # TypeScript and Python scripts now read VERSION file dynamically
    log_info "TypeScript and Python scripts will read version dynamically from VERSION file"
    
    log_success "All package files updated to version $version"
}

# Function to show current version status
show_version_status() {
    local current_version=$(get_current_version)
    
    echo "Current version: $current_version"
    echo ""
    echo "Version in package files:"
    
    # Check vcpkg.json
    if [ -f "$PROJECT_ROOT/vcpkg.json" ]; then
        local vcpkg_version=$(grep '"version"' "$PROJECT_ROOT/vcpkg.json" | sed 's/.*"version": "\([^"]*\)".*/\1/')
        echo "  vcpkg.json: $vcpkg_version"
    fi
    
    # Check Python setup.py
    if [ -f "$PROJECT_ROOT/python/setup.py" ]; then
        local python_version=$(grep 'version=' "$PROJECT_ROOT/python/setup.py" | sed 's/.*version="\([^"]*\)".*/\1/')
        echo "  python/setup.py: $python_version"
    fi
    
    # Check TypeScript script
    if [ -f "$PROJECT_ROOT/scripts/typescript_publish.sh" ]; then
        local ts_version="Dynamic (reads from VERSION file)"
        echo "  typescript_publish.sh: $ts_version"
    fi
    
    # Check Python script
    if [ -f "$PROJECT_ROOT/scripts/python_publish.sh" ]; then
        local py_version="Dynamic (reads from VERSION file)"
        echo "  python_publish.sh: $py_version"
    fi
}

# Function to create git tag for version
tag_version() {
    local version=$(get_current_version)
    local tag="v$version"
    
    if git tag -l | grep -q "^$tag$"; then
        log_warning "Tag $tag already exists"
        return 1
    fi
    
    git tag -a "$tag" -m "Version $version"
    log_success "Created git tag: $tag"
    
    echo "To push the tag, run: git push origin $tag"
}

# Function to show usage
show_usage() {
    cat << EOF
EpochProtos Version Manager

Usage: $0 <command> [arguments]

Commands:
  get                 - Show current version
  set <version>       - Set version (e.g., 1.2.3)
  bump [type]         - Bump version (major, minor, patch - default: patch)
  update              - Update all package files with current version
  status              - Show version status across all files
  tag                 - Create git tag for current version
  release [type]      - Bump version, update all files, and create tag

Examples:
  $0 get                    # Show current version
  $0 set 1.2.3             # Set version to 1.2.3
  $0 bump patch            # Bump patch version (1.0.0 -> 1.0.1)
  $0 bump minor            # Bump minor version (1.0.1 -> 1.1.0)
  $0 bump major            # Bump major version (1.1.0 -> 2.0.0)
  $0 update                # Update all package files
  $0 status                # Show version status
  $0 tag                   # Create git tag
  $0 release minor         # Bump minor, update all files, and tag

EOF
}

# Main command handling
case "${1:-help}" in
    "get")
        get_current_version
        ;;
    "set")
        set_version "$2"
        ;;
    "bump")
        bump_version "${2:-patch}"
        ;;
    "update")
        update_all_versions
        ;;
    "status")
        show_version_status
        ;;
    "tag")
        tag_version
        ;;
    "release")
        bump_type="${2:-patch}"
        log_info "Creating release with $bump_type version bump..."
        new_version=$(bump_version "$bump_type")
        update_all_versions
        tag_version
        log_success "Release $new_version created successfully!"
        ;;
    "help"|*)
        show_usage
        exit 1
        ;;
esac