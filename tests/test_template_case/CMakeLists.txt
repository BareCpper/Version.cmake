cmake_minimum_required(VERSION 3.20)
project(test_template_case LANGUAGES NONE)

# Verify: the lowercase "version.hpp" spelling still selects the shipped
# CMake/Version.hpp.in.
#
# Resolution must not rest on EXISTS, which is case-insensitive on Windows and
# macOS and case-sensitive on Linux: one project would then produce constexpr
# constants on one platform and fall through to the C-macro template on
# another, with nothing in the log to say so.
set(VERSION_H_FILENAME "version.hpp")
set(VERSION_NAMESPACE  "cased::version")

include("${VERSION_CMAKE_DIR}/Version.cmake")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
