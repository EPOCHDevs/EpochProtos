cmake_minimum_required(VERSION 3.20)
project(EpochProtosExample VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find the EpochProtos package
find_package(EpochProtos CONFIG REQUIRED)

# Create example executable
add_executable(example main.cpp)

# Link against EpochProtos
target_link_libraries(example PRIVATE EpochProtos::epoch_protos_cpp)

# Print found package info
message(STATUS "Found EpochProtos: ${EpochProtos_VERSION}")
message(STATUS "EpochProtos targets: EpochProtos::epoch_protos_cpp")
