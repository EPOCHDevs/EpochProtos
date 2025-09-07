vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO epochlab/epoch-protos
    REF "v${VERSION}"
    SHA512 0  # This should be updated with actual SHA512 when publishing
    HEAD_REF main
)

# Check if protobuf is available
vcpkg_find_acquire_program(PROTOC)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DPROTOBUF_PROTOC_EXECUTABLE=${PROTOC}
        -DBUILD_PYTHON_PROTOS=OFF  # Disable by default for vcpkg
        -DBUILD_TYPESCRIPT_PROTOS=OFF  # Disable by default for vcpkg
    MAYBE_UNUSED_VARIABLES
        BUILD_PYTHON_PROTOS
        BUILD_TYPESCRIPT_PROTOS
)

vcpkg_cmake_build()

vcpkg_cmake_install()

# Remove debug include directory if it exists
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/include")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
endif()

# Install proto files
file(INSTALL "${SOURCE_PATH}/proto/" 
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/proto"
     FILES_MATCHING PATTERN "*.proto")

# Handle copyright
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

# Create and install usage file
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" [[
epoch-protos provides CMake targets:

    find_package(EpochProtos CONFIG REQUIRED)
    target_link_libraries(main PRIVATE epoch_protos_cpp)

The package also installs .proto files to share/epoch-protos/proto/ for custom code generation.
]])

# Export CMake targets
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/EpochProtos)
