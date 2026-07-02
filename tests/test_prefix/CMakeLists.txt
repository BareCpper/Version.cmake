cmake_minimum_required(VERSION 3.20)
project(test_prefix LANGUAGES NONE)

# Verify: VERSION_PREFIX scopes C macro names (e.g. MYLIB_ prefix).
set(VERSION_PREFIX "MYLIB_")

include("${VERSION_CMAKE_DIR}/Version.cmake")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
