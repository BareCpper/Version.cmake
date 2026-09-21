# check.cmake: verify the custom template sentinel is present in the output,
# and that the template it came from is the one outside the package directory.
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
file(READ "${BIN_DIR}/template_path.txt"    TEMPLATE_PATH)
string(STRIP "${HEADER_PATH}"   HEADER_PATH)
string(STRIP "${TEMPLATE_PATH}" TEMPLATE_PATH)

if(NOT EXISTS "${HEADER_PATH}")
    message(FATAL_ERROR "Generated header not found: ${HEADER_PATH}")
endif()

file(READ "${HEADER_PATH}" CONTENT)

if(NOT "${CONTENT}" MATCHES "CUSTOM_TEMPLATE_SENTINEL")
    message(FATAL_ERROR
        "Custom template sentinel not found -- the default template was used instead")
endif()

# A bare macro name is what a template emits when substitution silently failed.
if(NOT "${CONTENT}" MATCHES "#define CUSTOM_MAJOR[ 	]+[0-9]+")
    message(FATAL_ERROR "Expected '#define CUSTOM_MAJOR <value>' not found in:
${CONTENT}")
endif()

# The template must not have been relocated into the package directory: that
# relocation is what made the documented VERSION_H_TEMPLATE setting inert.
string(FIND "${TEMPLATE_PATH}" "${BIN_DIR}" FOUND)
if(FOUND EQUAL -1)
    message(FATAL_ERROR
        "VERSION_H_TEMPLATE '${TEMPLATE_PATH}' is not the caller-supplied path under '${BIN_DIR}'")
endif()

message(STATUS "test_custom_template: PASSED -- caller-supplied template outside the package was used")
