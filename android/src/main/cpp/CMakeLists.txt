cmake_minimum_required(VERSION 3.18.1)

project("device_trust_native")

# C++17 standard & optimization
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden -O2 -Wall")

# Enable native logging in debug builds
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG")

# Build shared library
add_library(
    device_trust_native
    SHARED
    device_trust_native.cpp
)

# Link with Android log, dl, android libs
find_library(log-lib log)
find_library(android-lib android)

target_link_libraries(
    device_trust_native
    ${log-lib}
    ${android-lib}
    dl
)

# Support 16KB page size for Android 15+
if(ANDROID)
    target_link_options(device_trust_native PRIVATE -Wl,-z,max-page-size=16384)
endif()
