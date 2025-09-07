cmake_minimum_required(VERSION 3.20)
project(EpochProtos VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Options for controlling build features
option(BUILD_PYTHON_PROTOS "Build Python protobuf files" ON)
option(BUILD_TYPESCRIPT_PROTOS "Build TypeScript protobuf files" ON)
option(INSTALL_PROTO_FILES "Install .proto source files" ON)

# Find required packages
find_package(Protobuf REQUIRED)

# PkgConfig is optional for vcpkg builds
if(NOT VCPKG_TOOLCHAIN)
    find_package(PkgConfig)
endif()

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
)

# Generate C++ files
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILES})

# Create C++ library
add_library(epoch_protos_cpp STATIC ${PROTO_SRCS} ${PROTO_HDRS})

# Use modern CMake target-based approach
if(TARGET protobuf::libprotobuf)
    target_link_libraries(epoch_protos_cpp PUBLIC protobuf::libprotobuf)
else()
    target_link_libraries(epoch_protos_cpp PUBLIC ${Protobuf_LIBRARIES})
    target_include_directories(epoch_protos_cpp PUBLIC ${Protobuf_INCLUDE_DIRS})
endif()

# Set public include directories for consumers
target_include_directories(epoch_protos_cpp PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
    $<INSTALL_INTERFACE:include>
)

# Set output directory for generated files (only for local builds)
if(NOT VCPKG_TOOLCHAIN)
    set_target_properties(epoch_protos_cpp PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY ${PROTO_GENERATED_DIR}/cpp
    )
endif()

# Add alias for consistency
add_library(EpochProtos::epoch_protos_cpp ALIAS epoch_protos_cpp)

# Custom target to generate Python files (optional)
if(BUILD_PYTHON_PROTOS)
    add_custom_target(generate_python_protos
        COMMAND ${Protobuf_PROTOC_EXECUTABLE}
            --proto_path=${PROTO_SRC_DIR}
            --python_out=${PROTO_GENERATED_DIR}/python
            --pyi_out=${PROTO_GENERATED_DIR}/python
            ${PROTO_FILES}
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
            ${PROTO_GENERATED_DIR}/python/__init__.py
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/python/setup.py
            ${PROTO_GENERATED_DIR}/python/setup.py
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
message(STATUS "  C++ library: epoch_protos_cpp")
