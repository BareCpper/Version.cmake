cmake_minimum_required(VERSION 3.20)
project(test_basic LANGUAGES NONE)

# Verify: default C-preprocessor output; all VERSION_* variables populated.
include("${VERSION_CMAKE_DIR}/Version.cmake")

if(NOT VERSION_SET)
    message(FATAL_ERROR "VERSION_SET is false -- version parsing failed")
endif()

# Emit the generated header path so the check script can find it
file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
