cmake_minimum_required(VERSION 3.20)
project(test_out_dir_override LANGUAGES NONE)

# Verify PR #7 fix: VERSION_OUT_DIR set before including Version.cmake is preserved.
set(VERSION_OUT_DIR "${CMAKE_BINARY_DIR}/custom_include")

include("${VERSION_CMAKE_DIR}/Version.cmake")

# After include, VERSION_OUT_DIR must still be our custom path -- not overwritten.
if(NOT "${VERSION_OUT_DIR}" STREQUAL "${CMAKE_BINARY_DIR}/custom_include")
    message(FATAL_ERROR
        "VERSION_OUT_DIR was overwritten!\n"
        "  Expected: ${CMAKE_BINARY_DIR}/custom_include\n"
        "  Got:      ${VERSION_OUT_DIR}")
endif()

file(WRITE "${CMAKE_BINARY_DIR}/out_dir.txt"     "${VERSION_OUT_DIR}")
file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
