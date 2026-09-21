# check.cmake: the header must be the C++ one, not the C-macro fall-through.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" CONTENT)

if(NOT "${CONTENT}" MATCHES "namespace cased::version")
    message(FATAL_ERROR
        "Version.hpp.in was not selected for the lowercase 'version.hpp' request:
${HEADER_PATH}
${CONTENT}")
endif()

if(NOT "${CONTENT}" MATCHES "inline constexpr")
    message(FATAL_ERROR "No constexpr constants in:
${HEADER_PATH}
${CONTENT}")
endif()

message(STATUS "test_template_case: PASSED -- 'version.hpp' resolved to the shipped Version.hpp.in")
