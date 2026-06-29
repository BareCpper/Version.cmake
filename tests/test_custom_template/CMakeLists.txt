cmake_minimum_required(VERSION 3.20)
project(test_custom_template LANGUAGES NONE)

# Verify: a user-supplied .in template is used instead of auto-generated one.
# The custom template emits a recognisable sentinel string.
set(VERSION_H_FILENAME "custom_version.h")

# Write a custom template into the CMake package directory location
# (Version.cmake looks there first for ${VERSION_H_FILENAME}.in)
file(WRITE
    "${VERSION_CMAKE_DIR}/${VERSION_H_FILENAME}.in"
    "/* CUSTOM_TEMPLATE_SENTINEL */\n"
    "#define CUSTOM_MAJOR @_VERSION_MAJOR@\n"
)

include("${VERSION_CMAKE_DIR}/Version.cmake")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
