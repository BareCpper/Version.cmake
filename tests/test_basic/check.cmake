# check.cmake: verify the generated Version.h contains expected C macros.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" HEADER_CONTENT)

# Each macro must be followed by a value. Matching the name alone passed against
# a header whose every field was empty -- "#define VERSION_MAJOR" with nothing
# after it -- which is how a version-less build shipped unnoticed.
foreach(MACRO VERSION_MAJOR VERSION_MINOR VERSION_PATCH VERSION_COMMIT
              VERSION_SHA VERSION_SEMANTIC VERSION_FULL
              VERSION_DATE VERSION_DATETIME)
    if(NOT "${HEADER_CONTENT}" MATCHES "#define ${MACRO}[ \t]+[^ \t\r\n]")
        message(FATAL_ERROR "Expected '#define ${MACRO} <value>' not found in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
    endif()
endforeach()

# The string macros survive the name-only check as `""`, so pin their contents
# too: an empty semantic version is the symptom the check above cannot see.
if(NOT "${HEADER_CONTENT}" MATCHES "#define VERSION_SEMANTIC \"[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\"")
    message(FATAL_ERROR "VERSION_SEMANTIC is not a dotted quad in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
endif()

message(STATUS "test_basic: PASSED -- all expected macros present with values")
