# check.cmake: with no repository the header still carries the project()
# version. The build-time regeneration runs `cmake -P` with the same empty
# source dir, so this also pins that the fallback survives that second pass.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" HEADER_CONTENT)

foreach(EXPECTED "VERSION_MAJOR 7" "VERSION_MINOR 8" "VERSION_PATCH 9"
                 "VERSION_SEMANTIC \"7.8.9.0\"" "VERSION_FULL \"7.8.9-0\"")
    if(NOT "${HEADER_CONTENT}" MATCHES "#define ${EXPECTED}")
        message(FATAL_ERROR "Expected '#define ${EXPECTED}' not found in:
${HEADER_PATH}
${HEADER_CONTENT}")
    endif()
endforeach()

message(STATUS "test_no_git_repo: PASSED -- an archive with no .git still yields the project() version")
