cmake_minimum_required(VERSION 3.20)
project(test_cpp23_namespace LANGUAGES NONE)

# Verify: VERSION_H_FILENAME=.hpp + VERSION_NAMESPACE selects Version.hpp.in
# and produces a constexpr namespace block. The canonical spelling is used
# here; test_template_case covers the differently-cased request.
set(VERSION_H_FILENAME "Version.hpp")
set(VERSION_NAMESPACE  "myapp::version")
set(VERSION_PREFIX     "MYAPP_")

include("${VERSION_CMAKE_DIR}/Version.cmake")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
