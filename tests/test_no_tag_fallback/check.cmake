# check.cmake: with no matching tag the header must still carry a complete
# version -- taken from project(VERSION 4.5.6) -- and never a bare macro name.
#
# The header is written by genCmakeVersion's separate `cmake -P` process, which
# has no project() of its own, so this also pins that VERSION_FALLBACK is
# forwarded into it. An unforwarded fallback silently re-defaults to 0.0.0 and
# the built header disagrees with the configure-time version.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" HEADER_CONTENT)

foreach(EXPECTED "VERSION_MAJOR 4" "VERSION_MINOR 5" "VERSION_PATCH 6"
                 "VERSION_COMMIT 2" "VERSION_SEMANTIC \"4.5.6.2\"")
    if(NOT "${HEADER_CONTENT}" MATCHES "#define ${EXPECTED}")
        message(FATAL_ERROR "Expected '#define ${EXPECTED}' not found in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
    endif()
endforeach()

if(NOT "${HEADER_CONTENT}" MATCHES "#define VERSION_SHA \"[0-9A-Fa-f]+\"")
    message(FATAL_ERROR "VERSION_SHA does not identify a commit in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
endif()

if(NOT "${HEADER_CONTENT}" MATCHES "#define VERSION_FULL \"4\\.5\\.6-2-g[0-9A-Fa-f]+\"")
    message(FATAL_ERROR "VERSION_FULL is not describe-shaped in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
endif()

message(STATUS "test_no_tag_fallback: PASSED -- no matching tag yields the project() version, not an empty header")
