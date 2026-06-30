# MIT License
# Copyright (c) 2022 craig-barecpper@crog.uk
# Distributed under the MIT License. See accompanying LICENSE or https://cmake.org/licensing for details.

# @note 3.20 required for `GENERATED` attribute to be project-wide
cmake_minimum_required(VERSION 3.20)

# TODO? if(DEFINED VERSION_SEMANTIC)
# return()
# endif()

message(CHECK_START "Version.cmake")
list(APPEND CMAKE_MESSAGE_INDENT "  ")

# ---------------------------------------------------------------------------
# Configuration variables
#
# VERSION_OUT_DIR     -- Directory for the generated header file.
#                        Default: CMAKE_BINARY_DIR.
#                        Override before including Version.cmake to place the
#                        header in a sub-directory, e.g.:
#                            set(VERSION_OUT_DIR "${CMAKE_BINARY_DIR}/include/myapp")
#
# VERSION_SOURCE_DIR  -- The git repository root to query.
#                        Default: CMAKE_SOURCE_DIR.
#                        Override for sub-module or CPM-fetched versioning.
#
# VERSION_PREFIX      -- Prefix for C preprocessor macros in the generated header,
#                        e.g. "MYAPP_" produces MYAPP_VERSION_MAJOR.
#                        Default: "" (no prefix). Set an explicit prefix when
#                        multiple libraries use Version.cmake in the same build.
#
# VERSION_NAMESPACE   -- C++ namespace for constexpr constants (Version.hpp.in).
#                        e.g. "myapp::version". Supports nested namespaces.
#                        Default: "" (constants at global scope).
#                        Only used when VERSION_H_FILENAME ends in ".hpp".
#
# VERSION_H_FILENAME  -- Output filename for the generated header.
#                        Default: "${VERSION_PREFIX}Version.h"
#                        Set to "version.hpp" (or "${VERSION_PREFIX}Version.hpp")
#                        to select CMake/Version.hpp.in (C++20/23 constexpr output).
# ---------------------------------------------------------------------------

# VERSION_OUT_DIR: only set the default when not already defined by the caller,
# and only when the value is empty. Using NOT DEFINED + STREQUAL "" avoids the
# boolean-truthiness trap where a value like "OFF" or a NOTFOUND path would be
# silently replaced (Copilot review on PR #7, comment 1).
if(NOT DEFINED VERSION_OUT_DIR OR "${VERSION_OUT_DIR}" STREQUAL "")
    set(VERSION_OUT_DIR "${CMAKE_BINARY_DIR}" CACHE PATH
        "Destination directory into which Version.cmake shall generate versioning header files")
endif()

set(VERSION_SOURCE_DIR "${CMAKE_SOURCE_DIR}" CACHE PATH
    "Repository directory used for Version.cmake repo versioning")
set(VERSION_PREFIX "" CACHE STRING
    "Prefix for generated files and C preprocessor definitions")
set(VERSION_NAMESPACE "" CACHE STRING
    "C++ namespace for constexpr constants in Version.hpp.in (e.g. myapp::version)")

# Configure-time build date (not a git-derived date).
string(TIMESTAMP VERSION_DATE     "%Y-%m-%d")
string(TIMESTAMP VERSION_DATETIME "%Y-%m-%dT%H:%M:%SZ")

# Get version information from git
message(CHECK_START "Find git")

if(NOT DEFINED GIT_EXECUTABLE)
    find_package(Git)

    if(NOT Git_FOUND)
        message(CHECK_FAIL "Not found in PATH")
    else()
        message(CHECK_PASS "Found: '${GIT_EXECUTABLE}'")
    endif()
else()
    message(CHECK_PASS "Using pre-defined GIT_EXECUTABLE: '${GIT_EXECUTABLE}'")
endif()

# Git describe
# @note Exclude 'tweak' tags in the form v0.1.2-30 to avoid a second suffix
set(GIT_VERSION_COMMAND "${GIT_EXECUTABLE}" -C "${VERSION_SOURCE_DIR}"
    --no-pager describe --tags
    --exclude "v[0-9]*[._][0-9]*[._][0-9]*-[0-9]*"
    --always --dirty --long)

# Git count (commits on current branch only, not merge-branch commits)
set(GIT_COUNT_COMMAND "${GIT_EXECUTABLE}" -C "${VERSION_SOURCE_DIR}"
    rev-list --count --first-parent HEAD)

# Git cache path (for dependency tracking in the custom target)
set(GIT_CACHE_PATH_COMMAND "${GIT_EXECUTABLE}" -C "${VERSION_SOURCE_DIR}"
    rev-parse --git-dir)

macro(version_parseSemantic semVer)
    if("${semVer}" MATCHES "^v?([0-9]+)[._]([0-9]+)[._]?([0-9]+)?[-]([0-9]+)[-][g]([._0-9A-Fa-f]+)[-]?(dirty)?$")
        set(_VERSION_SET TRUE)
        math(EXPR _VERSION_MAJOR  "${CMAKE_MATCH_1}+0")
        math(EXPR _VERSION_MINOR  "${CMAKE_MATCH_2}+0")
        math(EXPR _VERSION_PATCH  "${CMAKE_MATCH_3}+0")
        math(EXPR _VERSION_COMMIT "${CMAKE_MATCH_4}+0")
        set(_VERSION_SHA   "${CMAKE_MATCH_5}")
        set(_VERSION_DIRTY "${CMAKE_MATCH_6}")
        set(_VERSION_SEMANTIC "${_VERSION_MAJOR}.${_VERSION_MINOR}.${_VERSION_PATCH}.${_VERSION_COMMIT}")
        set(_VERSION_FULL "${semVer}")

        if("${VERSION_PREFIX}" STREQUAL "")
            set(_VERSION_PREFIX "")
        else()
            set(_VERSION_PREFIX "${VERSION_PREFIX}_")
        endif()
    else()
        set(_VERSION_SET FALSE)
    endif()
endmacro()

macro(version_export_variables)
    set(VERSION_SET      "${_VERSION_SET}"      CACHE INTERNAL "" FORCE)
    set(VERSION_MAJOR    "${_VERSION_MAJOR}"    CACHE INTERNAL "" FORCE)
    set(VERSION_MINOR    "${_VERSION_MINOR}"    CACHE INTERNAL "" FORCE)
    set(VERSION_PATCH    "${_VERSION_PATCH}"    CACHE INTERNAL "" FORCE)
    set(VERSION_COMMIT   "${_VERSION_COMMIT}"   CACHE INTERNAL "" FORCE)
    set(VERSION_SHA      "${_VERSION_SHA}"      CACHE INTERNAL "" FORCE)
    set(VERSION_DIRTY    "${_VERSION_DIRTY}"    CACHE INTERNAL "" FORCE)
    set(VERSION_SEMANTIC "${_VERSION_SEMANTIC}" CACHE INTERNAL "" FORCE)
    set(VERSION_FULL     "${_VERSION_FULL}"     CACHE INTERNAL "" FORCE)
    set(VERSION_DATE     "${VERSION_DATE}"      CACHE INTERNAL "" FORCE)
    set(VERSION_DATETIME "${VERSION_DATETIME}"  CACHE INTERNAL "" FORCE)

    # Compute C++ namespace open/close blocks for Version.hpp.in.
    # _VERSION_NAMESPACE_BEGIN / _VERSION_NAMESPACE_END are injected into
    # configure_file so the template does not need conditional logic.
    if("${VERSION_NAMESPACE}" STREQUAL "")
        set(_VERSION_NAMESPACE_BEGIN "")
        set(_VERSION_NAMESPACE_END   "")
    else()
        set(_VERSION_NAMESPACE_BEGIN "namespace ${VERSION_NAMESPACE} {")
        set(_VERSION_NAMESPACE_END   "} // namespace ${VERSION_NAMESPACE}")
    endif()
endmacro()

message(CHECK_START "Git Cache-Path")

if(DEFINED GIT_CACHE_PATH)
    message(CHECK_PASS "Using pre-defined GIT_CACHE_PATH '${GIT_CACHE_PATH}'")
else()
    execute_process(
        COMMAND ${GIT_CACHE_PATH_COMMAND}
        RESULT_VARIABLE _GIT_RESULT
        OUTPUT_VARIABLE GIT_CACHE_PATH
        ERROR_VARIABLE  _GIT_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
        ${capture_output}
    )

    if(NOT _GIT_RESULT EQUAL 0)
        message(CHECK_FAIL
            "Failed: ${GIT_CACHE_PATH_COMMAND}\nRESULT_VARIABLE:'${_GIT_RESULT}' \nOUTPUT_VARIABLE:'${GIT_CACHE_PATH}' \nERROR_VARIABLE:'${_GIT_ERROR}'")
    else()
        # git rev-parse --git-dir returns an absolute path in a git worktree.
        # Only prepend VERSION_SOURCE_DIR for the relative (.git) case.
        if(IS_ABSOLUTE "${GIT_CACHE_PATH}")
            file(TO_CMAKE_PATH "${GIT_CACHE_PATH}" GIT_CACHE_PATH)
        else()
            file(TO_CMAKE_PATH "${VERSION_SOURCE_DIR}/${GIT_CACHE_PATH}" GIT_CACHE_PATH)
        endif()
        message(CHECK_PASS "Success '${GIT_CACHE_PATH}'")
    endif()
endif()

message(CHECK_START "Git Describe")
execute_process(
    COMMAND ${GIT_VERSION_COMMAND}
    RESULT_VARIABLE _GIT_RESULT
    OUTPUT_VARIABLE git_describe
    ERROR_VARIABLE  _GIT_ERROR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    ${capture_output}
)

if(NOT _GIT_RESULT EQUAL 0)
    message(CHECK_FAIL
        "Failed: ${GIT_VERSION_COMMAND}\nResult:'${_GIT_RESULT}' Error:'${_GIT_ERROR}'")

    if("${_GIT_ERROR}" STREQUAL "fatal: bad revision 'HEAD'")
        set(_VERSION_NOT_GIT_REPO TRUE)
    endif()
else()
    message(CHECK_PASS "Success '${git_describe}'")

    message(CHECK_START "Parse version")
    version_parseSemantic(${git_describe})

    if(${_VERSION_SET})
        message(CHECK_PASS "Tag '${git_describe}' is a valid semantic version [${_VERSION_SEMANTIC}]")
        message(STATUS "Build date: ${VERSION_DATE}")
    else()
        message(CHECK_FAIL "'${git_describe}' is not a valid semantic-version e.g. 'v0.1.2-30'")
    endif()
endif()

if(NOT DEFINED _VERSION_FULL AND NOT _VERSION_NOT_GIT_REPO)
    message(CHECK_START "Fallback as Git-Count")
    execute_process(
        COMMAND ${GIT_COUNT_COMMAND}
        RESULT_VARIABLE _GIT_RESULT
        OUTPUT_VARIABLE git_count
        ERROR_VARIABLE  _GIT_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
        ${capture_output}
    )

    if(NOT _GIT_RESULT EQUAL 0)
        message(CHECK_FAIL
            "Failed: ${GIT_COUNT_COMMAND}\nResult:'${_GIT_RESULT}' Error:'${_GIT_ERROR}'")
    else()
        set(git_describe "0.0.0-${git_count}-g${git_describe}")
        version_parseSemantic(${git_describe})

        if(${VERSION_SET})
            message(CHECK_PASS "git-tag '${git_describe}' is a valid semantic version")
        else()
            message(CHECK_FAIL "'${git_describe}' is not a valid semantic-version e.g. 'v0.1.2-30'")
        endif()
    endif()
endif()

function(gitversion_configure_file VERSION_H_TEMPLATE VERSION_H)
    # Quote both args: paths with spaces will break configure_file otherwise
    # (Copilot review on PR #7, comment 4).
    configure_file("${VERSION_H_TEMPLATE}" "${VERSION_H}")
endfunction()

version_export_variables()

if(VERSION_GENERATE_NOW)
    gitversion_configure_file("${VERSION_H_TEMPLATE}" "${VERSION_H}")
else()
    # VERSION_H_FILENAME may be pre-set by the caller to override the default
    # (e.g. "version.hpp" for C++20/23 output). Only set the default when not
    # already defined so a parent project's setting is not clobbered.
    if(NOT DEFINED VERSION_H_FILENAME)
        set(VERSION_H_FILENAME "${VERSION_PREFIX}Version.h")
    endif()
    set(VERSION_H_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/${VERSION_H_FILENAME}.in")
    set(VERSION_H          "${VERSION_OUT_DIR}/${VERSION_H_FILENAME}")

    message(CHECK_START "Find '${VERSION_H_FILENAME}.in'")

    if(NOT EXISTS "${VERSION_H_TEMPLATE}")
        set(VERSION_H_TEMPLATE "${VERSION_OUT_DIR}/${VERSION_H_FILENAME}.in")
        message(CHECK_FAIL "Not Found. Generating '${VERSION_H_TEMPLATE}'")

        # Auto-generate a minimal C-preprocessor template when none is provided.
        # For C++20/23 output, set VERSION_H_FILENAME to a .hpp name and provide
        # a Version.hpp.in template (CMake/Version.hpp.in is included in this package).
        file(WRITE "${VERSION_H_TEMPLATE}"
            [=[
#define @_VERSION_PREFIX@VERSION_MAJOR @_VERSION_MAJOR@
#define @_VERSION_PREFIX@VERSION_MINOR @_VERSION_MINOR@
#define @_VERSION_PREFIX@VERSION_PATCH @_VERSION_PATCH@
#define @_VERSION_PREFIX@VERSION_COMMIT @_VERSION_COMMIT@
#define @_VERSION_PREFIX@VERSION_SHA "@_VERSION_SHA@"
#define @_VERSION_PREFIX@VERSION_SEMANTIC "@_VERSION_SEMANTIC@"
#define @_VERSION_PREFIX@VERSION_FULL "@_VERSION_FULL@"
#define @_VERSION_PREFIX@VERSION_DATE "@VERSION_DATE@"
#define @_VERSION_PREFIX@VERSION_DATETIME "@VERSION_DATETIME@"
            ]=])

        if(NOT EXISTS "${VERSION_H_TEMPLATE}")
            message(FATAL_ERROR "Failed to create template ${VERSION_H_TEMPLATE}")
        endif()
    else()
        message(CHECK_PASS "Found '${VERSION_H_TEMPLATE}'")
    endif()

    # Custom target regenerates the header on every build by tracking git HEAD/index.
    add_custom_target(genCmakeVersion
        ALL
        BYPRODUCTS "${VERSION_H}"
        SOURCES    "${VERSION_H_TEMPLATE}"
        DEPENDS
            "${GIT_CACHE_PATH}/index"
            "${GIT_CACHE_PATH}/HEAD"
        COMMENT "Version.cmake: Generating '${VERSION_H_FILENAME}'"
        COMMAND "${CMAKE_COMMAND}"
            # Quote all -D args to handle paths with spaces and list variables
            # with semicolons (Copilot review on PR #7, comment 6).
            "-DVERSION_GENERATE_NOW=YES"
            "-DVERSION_H_TEMPLATE=${VERSION_H_TEMPLATE}"
            "-DVERSION_H=${VERSION_H}"
            "-DVERSION_PREFIX=${VERSION_PREFIX}"
            "-DVERSION_NAMESPACE=${VERSION_NAMESPACE}"
            "-DGIT_EXECUTABLE=${GIT_EXECUTABLE}"
            "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}"
            -B "${VERSION_OUT_DIR}"
            -P "${CMAKE_CURRENT_LIST_FILE}"
        WORKING_DIRECTORY "${VERSION_SOURCE_DIR}"
        VERBATIM
    )

    add_library(cmakeVersion INTERFACE)
    target_include_directories(cmakeVersion INTERFACE "${VERSION_OUT_DIR}")

    # Explicit filenames: prevent CMake finding Version.h.in for Version.h
    if(POLICY CMP0115)
        cmake_policy(SET CMP0115 NEW)
    endif()

    target_sources(cmakeVersion INTERFACE "${VERSION_H}")
    add_dependencies(cmakeVersion INTERFACE genCmakeVersion)

    add_library(version::version ALIAS cmakeVersion)
endif()

list(POP_BACK CMAKE_MESSAGE_INDENT)

if(VERSION_GENERATE_NOW)
    set(VERSION_H_GENERATED TRUE)
else()
    get_source_file_property(VERSION_H_GENERATED "${VERSION_H}" GENERATED)
endif()

if(NOT _VERSION_NOT_GIT_REPO)
    if(NOT VERSION_SET)
        message(CHECK_FAIL "Version.cmake failed - VERSION_SET==false")
    elseif(${VERSION_H_GENERATED})
        message(CHECK_PASS "${VERSION_FULL} [${VERSION_SEMANTIC}] {Generated}")
    elseif(EXISTS "${VERSION_H}")
        message(CHECK_PASS "Using pre-defined '${VERSION_H}'")
    else()
        message(CHECK_FAIL "Failed, ${VERSION_H} not available")
    endif()
else()
    message(CHECK_FAIL "Failed, Error reading Git repository")
endif()
