cmake_minimum_required(VERSION 3.20)

# We support Version.cmake usage before project() when cross-compiling.
# Avoid calling project() as CMake will set up a compiler at that point.
get_directory_property(hasParent PARENT_DIRECTORY)
if(NOT hasParent OR PROJECT_IS_TOP_LEVEL)
    project(Version.cmake)
endif()

include(CMake/Version.cmake)

# ---------------------------------------------------------------------------
# Tests -- only added when this is the top-level project (not a submodule).
# Run with: cmake --preset default && ctest --preset default
# ---------------------------------------------------------------------------
option(VERSION_CMAKE_BUILD_TESTS "Build Version.cmake test suite" ON)

if(VERSION_CMAKE_BUILD_TESTS AND PROJECT_IS_TOP_LEVEL)
    enable_testing()
    add_subdirectory(tests)
endif()
