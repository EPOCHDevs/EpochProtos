cmake_minimum_required(VERSION 3.20)

# Set up vcpkg integration if available
if(DEFINED ENV{VCPKG_ROOT})
    set(CMAKE_TOOLCHAIN_FILE $ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake CACHE STRING "Vcpkg toolchain file")
elseif(EXISTS "$ENV{HOME}/vcpkg/scripts/buildsystems/vcpkg.cmake")
    set(CMAKE_TOOLCHAIN_FILE $ENV{HOME}/vcpkg/scripts/buildsystems/vcpkg.cmake CACHE STRING "Vcpkg toolchain file")
endif()

# Enable vcpkg manifest mode if vcpkg is being used
if(CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg.cmake")
    set(VCPKG_MANIFEST_MODE ON)
    set(VCPKG_FEATURE_FLAGS "versions")
    message(STATUS "Using vcpkg toolchain: ${CMAKE_TOOLCHAIN_FILE}")
else()
    message(STATUS "vcpkg not found, using system packages")
endif()

project(EpochProtos VERSION 2.0.8 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Options for controlling build features
option(BUILD_PYTHON_PROTOS "Build Python protobuf files" ON)
option(BUILD_TYPESCRIPT_PROTOS "Build TypeScript protobuf files" ON)
option(INSTALL_PROTO_FILES "Install .proto source files" ON)
option(BUNDLE_PROTOBUF_RUNTIME "Bundle protobuf runtime into C++ library (no external dependency for consumers)" OFF)

# Prefer static protobuf when bundling
if(BUNDLE_PROTOBUF_RUNTIME)
    set(Protobuf_USE_STATIC_LIBS ON)
endif()

# Find required packages
find_package(Protobuf REQUIRED)

# Find PkgConfig
find_package(PkgConfig)

# Set proto source directory
set(PROTO_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/proto)
set(PROTO_GENERATED_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated)

# Create output directories
file(MAKE_DIRECTORY ${PROTO_GENERATED_DIR}/cpp)
file(MAKE_DIRECTORY ${PROTO_GENERATED_DIR}/python)
file(MAKE_DIRECTORY ${PROTO_GENERATED_DIR}/typescript)

# Proto files
set(PROTO_FILES
    ${PROTO_SRC_DIR}/common.proto
    ${PROTO_SRC_DIR}/chart_def.proto
    ${PROTO_SRC_DIR}/table_def.proto
    ${PROTO_SRC_DIR}/tearsheet.proto
)

# Generate C++ files using custom command (to avoid generating WKT files)
# Generate into epoch_protos/ subdirectory for easier include paths
set(PROTO_SRCS)
set(PROTO_HDRS)
foreach(PROTO_FILE ${PROTO_FILES})
    get_filename_component(PROTO_NAME ${PROTO_FILE} NAME_WE)
    set(PROTO_SRC ${CMAKE_CURRENT_BINARY_DIR}/epoch_protos/${PROTO_NAME}.pb.cc)
    set(PROTO_HDR ${CMAKE_CURRENT_BINARY_DIR}/epoch_protos/${PROTO_NAME}.pb.h)

    add_custom_command(
        OUTPUT ${PROTO_SRC} ${PROTO_HDR}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/epoch_protos
        COMMAND ${Protobuf_PROTOC_EXECUTABLE}
            --proto_path=${PROTO_SRC_DIR}
            --proto_path=${Protobuf_INCLUDE_DIRS}
            --cpp_out=${CMAKE_CURRENT_BINARY_DIR}/epoch_protos
            ${PROTO_FILE}
        DEPENDS ${PROTO_FILE}
        COMMENT "Generating C++ protobuf files for ${PROTO_NAME}"
        VERBATIM
    )

    list(APPEND PROTO_SRCS ${PROTO_SRC})
    list(APPEND PROTO_HDRS ${PROTO_HDR})
endforeach()

# Create C++ library
if(BUNDLE_PROTOBUF_RUNTIME)
    add_library(epoch_protos_cpp SHARED ${PROTO_SRCS} ${PROTO_HDRS})
    set_target_properties(epoch_protos_cpp PROPERTIES POSITION_INDEPENDENT_CODE ON)
else()
    add_library(epoch_protos_cpp STATIC ${PROTO_SRCS} ${PROTO_HDRS})
    # Enable PIC for static library to allow linking into shared libraries
    set_target_properties(epoch_protos_cpp PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

# Use modern CMake target-based approach
if(TARGET protobuf::libprotobuf)
    if(BUNDLE_PROTOBUF_RUNTIME)
        target_link_libraries(epoch_protos_cpp PRIVATE protobuf::libprotobuf)
    else()
        target_link_libraries(epoch_protos_cpp PUBLIC protobuf::libprotobuf)
    endif()
else()
    if(BUNDLE_PROTOBUF_RUNTIME)
        target_link_libraries(epoch_protos_cpp PRIVATE ${Protobuf_LIBRARIES})
    else()
        target_link_libraries(epoch_protos_cpp PUBLIC ${Protobuf_LIBRARIES})
    endif()
    target_include_directories(epoch_protos_cpp PUBLIC ${Protobuf_INCLUDE_DIRS})
endif()

# Set public include directories for consumers
target_include_directories(epoch_protos_cpp PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
    $<INSTALL_INTERFACE:include>
)

# Set output directory for generated files
set_target_properties(epoch_protos_cpp PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${PROTO_GENERATED_DIR}/cpp
)

# Add aliases for consistency and cleaner naming
add_library(EpochProtos::epoch_protos_cpp ALIAS epoch_protos_cpp)
add_library(epoch::protos ALIAS epoch_protos_cpp)

# Custom target to generate Python files (optional)
if(BUILD_PYTHON_PROTOS)
    add_custom_target(generate_python_protos
        COMMAND ${CMAKE_COMMAND} -E make_directory ${PROTO_GENERATED_DIR}/python/epoch_protos
        COMMAND ${Protobuf_PROTOC_EXECUTABLE}
            --proto_path=${PROTO_SRC_DIR}
            --python_out=${PROTO_GENERATED_DIR}/python/epoch_protos
            --pyi_out=${PROTO_GENERATED_DIR}/python/epoch_protos
            ${PROTO_FILES}
        COMMAND ${CMAKE_COMMAND} -E env python3 ${CMAKE_CURRENT_SOURCE_DIR}/scripts/fix_python_imports.py ${PROTO_GENERATED_DIR}/python/epoch_protos
        DEPENDS ${PROTO_FILES}
        COMMENT "Generating Python protobuf files"
    )
endif()

# Custom target to generate TypeScript files (optional, requires protoc-gen-ts)
if(BUILD_TYPESCRIPT_PROTOS)
    find_program(PROTOC_GEN_TS protoc-gen-ts)
    if(PROTOC_GEN_TS)
        add_custom_target(generate_typescript_protos
            COMMAND ${Protobuf_PROTOC_EXECUTABLE}
                --proto_path=${PROTO_SRC_DIR}
                --plugin=protoc-gen-ts=${PROTOC_GEN_TS}
                --ts_out=${PROTO_GENERATED_DIR}/typescript
                ${PROTO_FILES}
            DEPENDS ${PROTO_FILES}
            COMMENT "Generating TypeScript protobuf files"
        )
    else()
        message(WARNING "protoc-gen-ts not found. TypeScript generation will be skipped.")
    endif()
endif()

# Create Python package structure (optional)
if(BUILD_PYTHON_PROTOS AND TARGET generate_python_protos)
    add_custom_target(setup_python_package
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/python/__init__.py
            ${PROTO_GENERATED_DIR}/python/epoch_protos/__init__.py
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/python/setup.py
            ${PROTO_GENERATED_DIR}/python/setup.py
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/python/pyproject.toml
            ${PROTO_GENERATED_DIR}/python/pyproject.toml
        DEPENDS generate_python_protos
        COMMENT "Setting up Python package structure"
    )
endif()

# Create TypeScript package structure (optional)
if(BUILD_TYPESCRIPT_PROTOS AND TARGET generate_typescript_protos)
    add_custom_target(setup_typescript_package
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/typescript/package.json
            ${PROTO_GENERATED_DIR}/typescript/package.json
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/typescript/tsconfig.json
            ${PROTO_GENERATED_DIR}/typescript/tsconfig.json
        DEPENDS generate_typescript_protos
        COMMENT "Setting up TypeScript package structure"
    )
endif()

# Master target to generate all language bindings
set(ALL_PROTO_TARGETS epoch_protos_cpp)
if(TARGET generate_python_protos)
    list(APPEND ALL_PROTO_TARGETS generate_python_protos)
endif()
if(TARGET generate_typescript_protos)
    list(APPEND ALL_PROTO_TARGETS generate_typescript_protos)
endif()
if(TARGET setup_python_package)
    list(APPEND ALL_PROTO_TARGETS setup_python_package)
endif()
if(TARGET setup_typescript_package)
    list(APPEND ALL_PROTO_TARGETS setup_typescript_package)
endif()

add_custom_target(generate_all_protos DEPENDS ${ALL_PROTO_TARGETS})

# Install targets with proper export
install(TARGETS epoch_protos_cpp
    EXPORT EpochProtosTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

# Install generated headers
message(STATUS "PROTO_HDRS: ${PROTO_HDRS}")
install(FILES ${PROTO_HDRS}
    DESTINATION include/epoch_protos
)

# Install proto files if requested
if(INSTALL_PROTO_FILES)
    install(FILES ${PROTO_FILES}
        DESTINATION share/epoch-protos/proto
    )
endif()

# Export targets for find_package
install(EXPORT EpochProtosTargets
    FILE EpochProtosTargets.cmake
    NAMESPACE EpochProtos::
    DESTINATION lib/cmake/EpochProtos
)

# Create a config file for other projects to find this package
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/EpochProtosConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/EpochProtosConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/EpochProtosConfig.cmake
    INSTALL_DESTINATION lib/cmake/EpochProtos
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/EpochProtosConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/EpochProtosConfigVersion.cmake
    DESTINATION lib/cmake/EpochProtos
)

# Print status
message(STATUS "EpochProtos configuration:")
message(STATUS "  Proto files: ${PROTO_FILES}")
message(STATUS "  Generated directory: ${PROTO_GENERATED_DIR}")
message(STATUS "  C++ library: epoch_protos_cpp (bundle protobuf: ${BUNDLE_PROTOBUF_RUNTIME})")
