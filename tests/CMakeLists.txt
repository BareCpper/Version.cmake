cmake_minimum_required(VERSION 3.20)
project(VersionCmakeTests LANGUAGES NONE)

# ---------------------------------------------------------------------------
# Test strategy: each test is a sub-project that runs cmake --configure
# on a small CMakeLists.txt, then checks the generated header content using
# cmake -P scripts. CTest invokes each as a separate test case.
#
# Tests are ordered from simplest to most complex:
#   test_basic               -- default C-macro output; VERSION_* variables populated
#   test_out_dir_override    -- VERSION_OUT_DIR pre-set by parent is respected (PR #7)
#   test_prefix              -- VERSION_PREFIX scopes C macro names
#   test_cpp23_namespace     -- VERSION_H_FILENAME=.hpp + VERSION_NAMESPACE produces
#                               constexpr namespace block
#   test_custom_template     -- user-supplied .in file is preferred over auto-generated
# ---------------------------------------------------------------------------

enable_testing()

# Helper: configure a test sub-project into a unique binary dir,
# then run a check script that verifies the generated header.
function(add_version_test name)
    set(SRC_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
    set(BIN_DIR  "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    set(VERSION_CMAKE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../CMake")

    # Step 1: configure the test project
    add_test(NAME "${name}/configure"
        COMMAND "${CMAKE_COMMAND}"
            "-DVERSION_CMAKE_DIR=${VERSION_CMAKE_DIR}"
            -S "${SRC_DIR}"
            -B "${BIN_DIR}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    )
    set_tests_properties("${name}/configure" PROPERTIES
        FIXTURES_SETUP "${name}_fixture"
    )

    # Step 2: verify the generated header via check script
    add_test(NAME "${name}/check"
        COMMAND "${CMAKE_COMMAND}"
            "-DBIN_DIR=${BIN_DIR}"
            -P "${SRC_DIR}/check.cmake"
    )
    set_tests_properties("${name}/check" PROPERTIES
        FIXTURES_REQUIRED "${name}_fixture"
        DEPENDS           "${name}/configure"
    )
endfunction()

add_version_test(test_basic)
add_version_test(test_out_dir_override)
add_version_test(test_prefix)
add_version_test(test_cpp23_namespace)
add_version_test(test_custom_template)
