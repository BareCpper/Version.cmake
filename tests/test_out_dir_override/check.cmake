# check.cmake: verify the generated header landed in the overridden output dir.
file(READ "${BIN_DIR}/out_dir.txt"          OUT_DIR)
file(READ "${BIN_DIR}/generated_header.txt" HEADER_PATH)
string(STRIP "${OUT_DIR}"     OUT_DIR)
string(STRIP "${HEADER_PATH}" HEADER_PATH)

string(FIND "${HEADER_PATH}" "custom_include" FOUND)
if(FOUND EQUAL -1)
    message(FATAL_ERROR
        "Generated header '${HEADER_PATH}' is not inside the overridden VERSION_OUT_DIR '${OUT_DIR}'")
endif()

message(STATUS "test_out_dir_override: PASSED -- header in '${HEADER_PATH}'")
