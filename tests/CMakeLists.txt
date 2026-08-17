cmake_minimum_required(VERSION 3.20)
project(VersionCmakeTests LANGUAGES NONE)

# ---------------------------------------------------------------------------
# Test strategy: each test is a sub-project that runs cmake --configure
# on a small CMakeLists.txt, builds the genCmakeVersion target, then checks the
# generated header content using cmake -P scripts. CTest invokes each as a
# separate test case.
#
# Tests are ordered from simplest to most complex:
#   test_basic               -- default C-macro output; VERSION_* variables populated
#   test_out_dir_override    -- VERSION_OUT_DIR pre-set by parent is respected
#   test_prefix              -- VERSION_PREFIX scopes C macro names
#   test_cpp23_namespace     -- VERSION_H_FILENAME=.hpp + VERSION_NAMESPACE produces
#                               constexpr namespace block
#   test_custom_template     -- user-supplied .in file is preferred over auto-generated
#   test_tag_match           -- a non-version tag newer than the version tag is ignored
#   test_no_tag_fallback     -- no matching tag falls back to the project() version
#   test_tag_pattern_override-- VERSION_TAG_PATTERN accepts another tag convention
# ---------------------------------------------------------------------------

enable_testing()

# Helper: configure a test sub-project into a unique binary dir, build the
# version target, then run a check script that verifies the generated header.
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
        FIXTURES_SETUP "${name}_configured"
    )

    # Step 2: build the version target.
    #
    # configure_file runs inside genCmakeVersion's build-time `cmake -P`, not at
    # configure time, so the header does not exist until this step -- without it
    # the check below has no file to read. Building also exercises the -D
    # forwarding into that separate process, which is where a variable the
    # module forgets to forward shows up as a header disagreeing with the
    # configure-time version.
    #
    # --config is required by multi-config generators and ignored by the rest;
    # the sub-projects are LANGUAGES NONE, so any configuration will do.
    add_test(NAME "${name}/build"
        COMMAND "${CMAKE_COMMAND}"
            --build  "${BIN_DIR}"
            --target genCmakeVersion
            --config Debug
    )
    set_tests_properties("${name}/build" PROPERTIES
        FIXTURES_REQUIRED "${name}_configured"
        FIXTURES_SETUP    "${name}_built"
    )

    # Step 3: verify the generated header via check script
    add_test(NAME "${name}/check"
        COMMAND "${CMAKE_COMMAND}"
            "-DBIN_DIR=${BIN_DIR}"
            -P "${SRC_DIR}/check.cmake"
    )
    set_tests_properties("${name}/check" PROPERTIES
        FIXTURES_REQUIRED "${name}_built"
    )
endfunction()

add_version_test(test_basic)
add_version_test(test_out_dir_override)
add_version_test(test_prefix)
add_version_test(test_cpp23_namespace)
add_version_test(test_custom_template)
add_version_test(test_tag_match)
add_version_test(test_no_tag_fallback)
add_version_test(test_tag_pattern_override)
