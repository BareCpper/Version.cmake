# check.cmake: the compile itself is the assertion -- this confirms the
# executable that consumed the header was produced, so a build that quietly
# skipped the consumer target cannot pass as a compile.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

set(CONSUMER "${BIN_DIR}/consumer_built")

if(NOT EXISTS "${CONSUMER}")
    message(FATAL_ERROR "No consumer executable at '${CONSUMER}' -- the header was never compiled")
endif()

message(STATUS "test_generated_compiles: PASSED -- generated header compiles into ${CONSUMER}")
