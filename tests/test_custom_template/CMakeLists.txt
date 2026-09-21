cmake_minimum_required(VERSION 3.20)
project(test_custom_template LANGUAGES NONE)

# Verify: a template outside the Version.cmake package directory is used as-is.
#
# VERSION_H_TEMPLATE must not be relocated into the package directory. An
# installed or CPM-fetched copy is not the consumer's to write to, so a
# relocation leaves no way at all to supply a template.
set(VERSION_H_FILENAME "custom_version.h")
set(VERSION_H_TEMPLATE "${CMAKE_CURRENT_BINARY_DIR}/templates/${VERSION_H_FILENAME}.in")

file(WRITE "${VERSION_H_TEMPLATE}"
    "/* CUSTOM_TEMPLATE_SENTINEL */
"
    "#define CUSTOM_MAJOR @_VERSION_MAJOR@
"
)

include("${VERSION_CMAKE_DIR}/Version.cmake")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
file(WRITE "${CMAKE_BINARY_DIR}/template_path.txt"    "${VERSION_H_TEMPLATE}")
