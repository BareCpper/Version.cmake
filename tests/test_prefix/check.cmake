# check.cmake: verify prefixed macros are present and unprefixed ones are absent.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" CONTENT)

# Prefixed macros must be present
foreach(MACRO MYLIB_VERSION_MAJOR MYLIB_VERSION_MINOR MYLIB_VERSION_PATCH)
    if(NOT "${CONTENT}" MATCHES "#define ${MACRO}")
        message(FATAL_ERROR "Expected '#define ${MACRO}' not found")
    endif()
endforeach()

# Unprefixed VERSION_MAJOR must NOT be present (would indicate prefix was ignored)
if("${CONTENT}" MATCHES "#define VERSION_MAJOR ")
    message(FATAL_ERROR "Unprefixed '#define VERSION_MAJOR' found -- prefix was not applied")
endif()

message(STATUS "test_prefix: PASSED -- MYLIB_ prefix applied correctly")
