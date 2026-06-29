# check.cmake: verify the custom template sentinel is present in the output.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" CONTENT)

if(NOT "${CONTENT}" MATCHES "CUSTOM_TEMPLATE_SENTINEL")
    message(FATAL_ERROR
        "Custom template sentinel not found -- auto-generated template was used instead")
endif()

if(NOT "${CONTENT}" MATCHES "#define CUSTOM_MAJOR")
    message(FATAL_ERROR "Expected '#define CUSTOM_MAJOR' from custom template not found")
endif()

message(STATUS "test_custom_template: PASSED -- custom template was used")
