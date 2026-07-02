# check.cmake: verify C++20/23 constexpr namespace block is present.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" CONTENT)

# Namespace block must be present
if(NOT "${CONTENT}" MATCHES "namespace myapp::version")
    message(FATAL_ERROR "Expected 'namespace myapp::version' not found in:\n${HEADER_PATH}")
endif()

# constexpr constants must be present
foreach(CONST version_major version_minor version_patch version_commit
              version_sha version_string version_full version_date version_datetime)
    if(NOT "${CONTENT}" MATCHES "inline constexpr.*${CONST}")
        message(FATAL_ERROR "Expected 'inline constexpr ... ${CONST}' not found")
    endif()
endforeach()

# Prefixed C macros must also be present (both paths in one header)
foreach(MACRO MYAPP_VERSION_MAJOR MYAPP_VERSION_MINOR MYAPP_VERSION_DATE)
    if(NOT "${CONTENT}" MATCHES "#define ${MACRO}")
        message(FATAL_ERROR "Expected '#define ${MACRO}' not found")
    endif()
endforeach()

# Header must be a .hpp file
if(NOT "${HEADER_PATH}" MATCHES "\.hpp$")
    message(FATAL_ERROR "Expected .hpp extension, got: ${HEADER_PATH}")
endif()

message(STATUS "test_cpp23_namespace: PASSED -- constexpr namespace block present")
