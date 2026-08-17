# check.cmake: the header built from the fixture repository must carry the
# version from the v1.2.3 tag, not from the newer 'perfgate-pre-recovery' tag.
#
# Asserting the values rather than the macro names is the point: the defect this
# test pins emitted every macro name with nothing after it.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" HEADER_CONTENT)

foreach(EXPECTED "VERSION_MAJOR 1" "VERSION_MINOR 2" "VERSION_PATCH 3"
                 "VERSION_COMMIT 2" "VERSION_SEMANTIC \"1.2.3.2\"")
    if(NOT "${HEADER_CONTENT}" MATCHES "#define ${EXPECTED}")
        message(FATAL_ERROR "Expected '#define ${EXPECTED}' not found in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
    endif()
endforeach()

if(NOT "${HEADER_CONTENT}" MATCHES "#define VERSION_FULL \"v1\\.2\\.3-2-g[0-9A-Fa-f]+\"")
    message(FATAL_ERROR "VERSION_FULL is not the describe output of the v1.2.3 tag in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
endif()

message(STATUS "test_tag_match: PASSED -- non-version tag ignored in favour of v1.2.3")
