cmake_minimum_required(VERSION 3.20)
project(test_generated_compiles LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../TestSupport.cmake")

# Verify: the generated C++ header is valid C++ that a real target compiles and
# links against.
#
# Every other test reads the header as text, which cannot see a template that
# emits something the compiler rejects -- an integer field left empty, a
# namespace block that never closes, a missing include for std::string_view.
# Reaching the constants from static_assert also pins that they are usable in a
# constant expression, which is the reason for the constexpr template at all.
set(REPO "${CMAKE_BINARY_DIR}/repo")
version_test_gitInit("${REPO}")
version_test_gitCommit("${REPO}" "initial")
version_test_gitTag("${REPO}" "v2.3.4")
version_test_gitCommit("${REPO}" "work")

set(VERSION_SOURCE_DIR "${REPO}")
set(VERSION_OUT_DIR    "${CMAKE_BINARY_DIR}/include")
set(VERSION_H_FILENAME "Version.hpp")
set(VERSION_NAMESPACE  "compiled::version")
set(VERSION_PREFIX     "COMPILED_")

include("${VERSION_CMAKE_DIR}/Version.cmake")

add_executable(consumer consumer.cpp)
target_compile_features(consumer PRIVATE cxx_std_17)

# version::version alone must be enough: it carries the include directory and
# the ordering against the generation step. A consumer should not have to name
# genCmakeVersion to get a header that exists before its first compile.
target_link_libraries(consumer PRIVATE version::version)

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")

# Copied rather than located, because a multi-config generator puts the
# executable in a per-config sub-directory this check script cannot predict.
# Only a completed link produces the file, so its absence means the header
# never compiled -- which globbing for object files would have missed.
add_custom_command(TARGET consumer POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:consumer>" "${CMAKE_BINARY_DIR}/consumer_built"
    VERBATIM
)
