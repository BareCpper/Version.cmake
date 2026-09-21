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
#   test_template_case       -- a differently-cased filename selects the same template
#   test_custom_template     -- a template outside the package directory is honoured
#   test_generated_compiles  -- a real target compiles and links against the header
#   test_tag_match           -- a non-version tag newer than the version tag is ignored
#   test_no_tag_fallback     -- no matching tag falls back to the project() version
#   test_no_git_repo         -- a tree with no .git at all falls back the same way
#   test_tag_pattern_override-- VERSION_TAG_PATTERN accepts another tag convention
# ---------------------------------------------------------------------------

enable_testing()

# Helper: configure a test sub-project into a unique binary dir, build the
# version target, then run a check script that verifies the generated header.
# BUILD_TARGET names the target the build step builds; the default builds only
# the generation step. ENVIRONMENT is forwarded to every step of the test.
function(add_version_test name)
    cmake_parse_arguments(ARG "" "BUILD_TARGET" "ENVIRONMENT" ${ARGN})

    if(NOT DEFINED ARG_BUILD_TARGET)
        set(ARG_BUILD_TARGET "genCmakeVersion")
    endif()

    set(SRC_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
    set(BIN_DIR  "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    set(VERSION_CMAKE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../CMake")

    # The sub-projects inherit this build's generator rather than each picking
    # the platform default. Without it a Ninja build spawns ten Visual Studio
    # configures on Windows, which is most of the suite's runtime, and the
    # suite stops exercising the generator the developer actually uses.
    set(GENERATOR_ARGS -G "${CMAKE_GENERATOR}")

    if(CMAKE_GENERATOR_PLATFORM)
        list(APPEND GENERATOR_ARGS -A "${CMAKE_GENERATOR_PLATFORM}")
    endif()

    if(CMAKE_GENERATOR_TOOLSET)
        list(APPEND GENERATOR_ARGS -T "${CMAKE_GENERATOR_TOOLSET}")
    endif()

    if(CMAKE_MAKE_PROGRAM)
        list(APPEND GENERATOR_ARGS "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}")
    endif()

    # Step 1: configure the test project
    add_test(NAME "${name}/configure"
        COMMAND "${CMAKE_COMMAND}"
            ${GENERATOR_ARGS}
            "-DVERSION_CMAKE_DIR=${VERSION_CMAKE_DIR}"
            -S "${SRC_DIR}"
            -B "${BIN_DIR}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    )
    set_tests_properties("${name}/configure" PROPERTIES
        FIXTURES_SETUP "${name}_configured"
        ENVIRONMENT    "${ARG_ENVIRONMENT}"
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
    # --config is required by multi-config generators and ignored by the rest.
    add_test(NAME "${name}/build"
        COMMAND "${CMAKE_COMMAND}"
            --build  "${BIN_DIR}"
            --target "${ARG_BUILD_TARGET}"
            --config Debug
    )
    set_tests_properties("${name}/build" PROPERTIES
        FIXTURES_REQUIRED "${name}_configured"
        FIXTURES_SETUP    "${name}_built"
        ENVIRONMENT       "${ARG_ENVIRONMENT}"
    )

    # Step 3: verify the generated header via check script
    add_test(NAME "${name}/check"
        COMMAND "${CMAKE_COMMAND}"
            "-DBIN_DIR=${BIN_DIR}"
            -P "${SRC_DIR}/check.cmake"
    )
    set_tests_properties("${name}/check" PROPERTIES
        FIXTURES_REQUIRED "${name}_built"
        ENVIRONMENT       "${ARG_ENVIRONMENT}"
    )
endfunction()

add_version_test(test_basic)
add_version_test(test_out_dir_override)
add_version_test(test_prefix)
add_version_test(test_cpp23_namespace)
add_version_test(test_template_case)
add_version_test(test_custom_template)
add_version_test(test_tag_match)
add_version_test(test_no_tag_fallback)
add_version_test(test_tag_pattern_override)

# Builds the whole project, not just the generation step: the consumer target
# that compiles the header is the assertion.
add_version_test(test_generated_compiles BUILD_TARGET consumer)

# The fixture is an ordinary empty directory inside the build tree, so without
# a ceiling git would ascend out of it and describe this very checkout.
add_version_test(test_no_git_repo
    ENVIRONMENT "GIT_CEILING_DIRECTORIES=${CMAKE_CURRENT_BINARY_DIR}/test_no_git_repo"
)
