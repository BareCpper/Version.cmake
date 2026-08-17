# MIT License
# Copyright (c) 2022 craig-barecpper@crog.uk
# Distributed under the MIT License. See accompanying LICENSE or https://cmake.org/licensing for details.

# Helpers for tests that need a repository with a known tag history.
#
# A tag-selection test cannot describe the checkout running the suite: its tags
# depend on clone depth, on the fetch refspec, and on whoever tagged last. Each
# such test builds the exact history it means to pin, inside its own binary dir.

find_package(Git REQUIRED)

# Run git in `repo`, aborting the configure with the command output on failure.
# The identity is supplied per-invocation so the fixture does not depend on the
# machine having user.name/user.email configured.
function(version_test_git repo)
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" -C "${repo}"
                -c "user.name=Version.cmake tests"
                -c "user.email=tests@version.cmake"
                -c commit.gpgsign=false
                ${ARGN}
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _output
        ERROR_VARIABLE  _output
    )

    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "git ${ARGN} failed in '${repo}': ${_output}")
    endif()
endfunction()

# Create an empty repository at `repo`, discarding any previous fixture so a
# rerun cannot inherit tags written by an earlier version of the test.
function(version_test_gitInit repo)
    file(REMOVE_RECURSE "${repo}")
    file(MAKE_DIRECTORY "${repo}")
    version_test_git("${repo}" init --quiet)
endfunction()

# Empty commits keep the fixtures readable: the tests assert on commit *counts*
# and tag placement, never on file content.
function(version_test_gitCommit repo subject)
    version_test_git("${repo}" commit --quiet --allow-empty -m "${subject}")
endfunction()

function(version_test_gitTag repo tag)
    version_test_git("${repo}" tag "${tag}")
endfunction()

# Report both values on mismatch -- "expected 1.2.3, got 9.9.9" localises the
# failure without rerunning the test by hand.
function(version_test_assertEqual what actual expected)
    if(NOT "${actual}" STREQUAL "${expected}")
        message(FATAL_ERROR "${what}: expected '${expected}', got '${actual}'")
    endif()
endfunction()
