# check.cmake: the header must carry the un-prefixed 1.4.0 tag that only the
# overridden VERSION_TAG_PATTERN can select. The build step regenerates it in a
# separate process, so this also pins that the pattern is forwarded there.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" HEADER_CONTENT)

foreach(EXPECTED "VERSION_MAJOR 1" "VERSION_MINOR 4" "VERSION_PATCH 0"
                 "VERSION_COMMIT 1" "VERSION_SEMANTIC \"1.4.0.1\"")
    if(NOT "${HEADER_CONTENT}" MATCHES "#define ${EXPECTED}")
        message(FATAL_ERROR "Expected '#define ${EXPECTED}' not found in:\n${HEADER_PATH}\n${HEADER_CONTENT}")
    endif()
endforeach()

message(STATUS "test_tag_pattern_override: PASSED -- list-valued VERSION_TAG_PATTERN selected the un-prefixed tag")
