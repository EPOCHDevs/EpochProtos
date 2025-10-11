cmake_minimum_required(VERSION 3.20)
project(TestEpochProtos)

find_package(EpochProtos CONFIG REQUIRED)

# Test the alias
if(TARGET epoch::protos)
    message(STATUS "✅ epoch::protos target found!")
else()
    message(FATAL_ERROR "❌ epoch::protos target not found!")
endif()

# Test the original target
if(TARGET EpochProtos::epoch_protos_cpp)
    message(STATUS "✅ EpochProtos::epoch_protos_cpp target found!")
else()
    message(FATAL_ERROR "❌ EpochProtos::epoch_protos_cpp target not found!")
endif()

message(STATUS "✅ All tests passed! Both targets are available.")