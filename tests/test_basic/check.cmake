# check.cmake: verify the generated Version.h contains expected C macros.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" HEADER_CONTENT)

foreach(MACRO VERSION_MAJOR VERSION_MINOR VERSION_PATCH VERSION_COMMIT
              VERSION_SHA VERSION_SEMANTIC VERSION_FULL
              VERSION_DATE VERSION_DATETIME)
    if(NOT "${HEADER_CONTENT}" MATCHES "#define ${MACRO}")
        message(FATAL_ERROR "Expected '#define ${MACRO}' not found in:\n${HEADER_PATH}")
    endif()
endforeach()

message(STATUS "test_basic: PASSED -- all expected macros present")
