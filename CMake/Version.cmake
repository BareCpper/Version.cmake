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
#                        Set to "Version.hpp" (or "${VERSION_PREFIX}Version.hpp")
#                        to select the bundled CMake/Version.hpp.in (C++20/23
#                        constexpr output). The lookup for "${VERSION_H_FILENAME}.in"
#                        tries an exact match first, then falls back to a
#                        case-insensitive match in the same directory, so a
#                        differently-cased reference (e.g. "version.hpp") still
#                        finds "Version.hpp.in" on a case-sensitive filesystem --
#                        but prefer the exact case for portability and clarity.
#
# VERSION_H_TEMPLATE  -- Optional explicit path to the .in template file, bypassing
#                        the VERSION_H_FILENAME naming convention entirely. Set this
#                        (as a normal variable, before include()) when you do not want
#                        template selection to depend on filename casing at all.
#                        A configure-time error is raised if the path does not exist.
#
# VERSION_TAG_PATTERN -- glob(7) pattern(s) of tags `git describe` may select.
#                        Default: "v[0-9]*".
#                        A CMake list becomes one --match flag per element.
#                        Set to "" to consider every tag (no --match).
#
# VERSION_TAG_EXCLUDE_PATTERN
#                     -- glob(7) pattern(s) of tags `git describe` must reject.
#                        Default: "v[0-9]*[._][0-9]*[._][0-9]*-[0-9]*".
#                        A CMake list becomes one --exclude flag per element.
#                        Set to "" to reject nothing (no --exclude).
#
# VERSION_FALLBACK    -- "major.minor.patch" used when no tag supplies a version.
#                        Default: PROJECT_VERSION, else "0.0.0".
# ---------------------------------------------------------------------------

# VERSION_OUT_DIR: only set the default when not already defined by the caller,
# and only when the value is empty. Using NOT DEFINED + STREQUAL "" avoids the
# boolean-truthiness trap where a value like "OFF" or a NOTFOUND path would be
# silently replaced (Copilot review on PR #7, comment 1).
if(NOT DEFINED VERSION_OUT_DIR OR "${VERSION_OUT_DIR}" STREQUAL "")
    set(VERSION_OUT_DIR "${CMAKE_BINARY_DIR}" CACHE PATH
        "Destination directory into which Version.cmake shall generate versioning header files")
endif()

# Guarded for the same reason as VERSION_OUT_DIR above, and for one more:
# creating a cache entry drops a normal variable of the same name under
# CMP0126 OLD, which every caller with cmake_minimum_required below 3.21 gets.
# Callers set these as normal variables before include(), so unguarded cache
# defaults discarded them on the *first* configure and honoured them on every
# reconfigure -- a prefix that appeared only after the second cmake run.
if(NOT DEFINED VERSION_SOURCE_DIR)
    set(VERSION_SOURCE_DIR "${CMAKE_SOURCE_DIR}" CACHE PATH
        "Repository directory used for Version.cmake repo versioning")
endif()
if(NOT DEFINED VERSION_PREFIX)
    set(VERSION_PREFIX "" CACHE STRING
        "Prefix for generated files and C preprocessor definitions")
endif()
if(NOT DEFINED VERSION_NAMESPACE)
    set(VERSION_NAMESPACE "" CACHE STRING
        "C++ namespace for constexpr constants in Version.hpp.in (e.g. myapp::version)")
endif()

# Tag filters. Guarded with NOT DEFINED so a caller may pre-set either as a
# normal variable -- including to the empty string, which disables that filter.
if(NOT DEFINED VERSION_TAG_PATTERN)
    set(VERSION_TAG_PATTERN "v[0-9]*" CACHE STRING
        "glob(7) pattern(s) of tags git-describe may select; empty considers every tag")
endif()
if(NOT DEFINED VERSION_TAG_EXCLUDE_PATTERN)
    set(VERSION_TAG_EXCLUDE_PATTERN "v[0-9]*[._][0-9]*[._][0-9]*-[0-9]*" CACHE STRING
        "glob(7) pattern(s) of tags git-describe must reject; empty rejects nothing")
endif()

# Default the fallback to the version project() already declared, so a build
# with no usable tag reports the number the maintainer wrote down rather than
# nothing at all. PROJECT_VERSION is empty when Version.cmake is included
# before project(), or when project() carried no VERSION argument.
if(NOT DEFINED VERSION_FALLBACK)
    if("${PROJECT_VERSION}" STREQUAL "")
        set(VERSION_FALLBACK "0.0.0" CACHE STRING
            "major.minor.patch used when no git tag supplies a version")
    else()
        set(VERSION_FALLBACK "${PROJECT_VERSION}" CACHE STRING
            "major.minor.patch used when no git tag supplies a version")
    endif()
endif()

# Resolved macro prefix. Computed here rather than inside the parser so the
# generated header keeps its prefix even when parsing fails and the fallback
# below supplies the version instead.
#
# The separator is appended only when the caller has not already written one.
# VERSION_H_FILENAME defaults to "${VERSION_PREFIX}Version.h", so callers write
# the trailing underscore to get "MYAPP_Version.h" -- and unconditionally adding
# a second one turned the documented "MYAPP_" -> MYAPP_VERSION_MAJOR into
# MYAPP__VERSION_MAJOR. Callers who pass a bare "MYAPP" still get the separator.
if("${VERSION_PREFIX}" STREQUAL "" OR "${VERSION_PREFIX}" MATCHES "_$")
    set(_VERSION_PREFIX "${VERSION_PREFIX}")
else()
    set(_VERSION_PREFIX "${VERSION_PREFIX}_")
endif()
#
# VERSION_PARSE_FUNCTION -- name of a CMake macro that replaces the built-in semver parser.
# Set this before including Version.cmake (as a normal variable, not CACHE) to override.
# The macro receives the raw git-describe string and must set these variables in its scope:
#   _VERSION_SET      BOOL    -- TRUE on successful parse; FALSE otherwise
#   _VERSION_MAJOR    STRING  -- e.g. "6000"
#   _VERSION_MINOR    STRING  -- e.g. "6"
#   _VERSION_PATCH    STRING  -- e.g. "0"
#   _VERSION_COMMIT   STRING  -- commits since tag, e.g. "8099"
#   _VERSION_SHA      STRING  -- short SHA without describe's 'g' marker, e.g. "5347e4"
#   _VERSION_DIRTY    STRING  -- "dirty" when repo has uncommitted changes, else ""
#   _VERSION_SEMANTIC STRING  -- dotted quad: "${MAJOR}.${MINOR}.${PATCH}.${COMMIT}"
#   _VERSION_FULL     STRING  -- raw version string passed in
# Use a macro (not a function) so variables are set directly in the calling scope.
#
# VERSION_PARSE_MODULE -- optional path to a .cmake file defining VERSION_PARSE_FUNCTION's
# macro. Required for a custom parser to survive into genCmakeVersion's build-time
# re-invocation (a fresh `cmake -P` process, below): that process starts with none of
# the including project's variables or macro definitions, only what is explicitly
# passed via -D or loaded via include()/CMAKE_MODULE_PATH. A macro *name* forwarded
# as a string is not enough on its own -- the macro's *body* has to be loaded too.
# If your parser macro is defined directly in the including CMakeLists.txt (works fine
# for the configure-time parse below, since that runs in-process and already has it),
# set VERSION_PARSE_MODULE to a file containing the same macro so the build-time
# re-invocation can include() it and get an identical, consistent parse both times.
if(NOT DEFINED VERSION_PARSE_FUNCTION)
    set(VERSION_PARSE_FUNCTION "" CACHE STRING
        "Optional CMake macro name called instead of the built-in semver parser")
endif()
if(NOT DEFINED VERSION_PARSE_MODULE)
    set(VERSION_PARSE_MODULE "" CACHE FILEPATH
        "Optional .cmake file defining VERSION_PARSE_FUNCTION's macro -- included here and forwarded to genCmakeVersion's build-time re-invocation")
endif()
if(NOT "${VERSION_PARSE_MODULE}" STREQUAL "")
    include("${VERSION_PARSE_MODULE}")
endif()

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

# Git describe tag filters.
#
# --match confines `describe` to version-shaped tags. Without it every tag is a
# candidate, so a project that tags before a risky git operation (the common
# "<topic>-pre-<change>" safety tag) has that tag picked as its version: the
# parse then fails and the generated header carries no version at all.
#
# --exclude drops 'tweak' tags of the form v0.1.2-30, whose trailing "-30"
# collides with describe's own "-<commits>-g<sha>" suffix.
#
# git applies --exclude after --match, so an excluded tag stays excluded even
# when the match pattern accepts it. Both flags repeat, so a list-valued
# pattern expands to one flag per element.
set(_VERSION_TAG_FILTER_ARGS "")
foreach(_VERSION_TAG_GLOB IN LISTS VERSION_TAG_PATTERN)
    list(APPEND _VERSION_TAG_FILTER_ARGS --match "${_VERSION_TAG_GLOB}")
endforeach()
foreach(_VERSION_TAG_GLOB IN LISTS VERSION_TAG_EXCLUDE_PATTERN)
    list(APPEND _VERSION_TAG_FILTER_ARGS --exclude "${_VERSION_TAG_GLOB}")
endforeach()
unset(_VERSION_TAG_GLOB)

# Git describe
set(GIT_VERSION_COMMAND "${GIT_EXECUTABLE}" -C "${VERSION_SOURCE_DIR}"
    --no-pager describe --tags
    ${_VERSION_TAG_FILTER_ARGS}
    --always --dirty --long)

# Git count (commits on current branch only, not merge-branch commits)
set(GIT_COUNT_COMMAND "${GIT_EXECUTABLE}" -C "${VERSION_SOURCE_DIR}"
    rev-list --count --first-parent HEAD)

# Git short SHA, for the fallback path where describe yielded nothing parseable
set(GIT_SHA_COMMAND "${GIT_EXECUTABLE}" -C "${VERSION_SOURCE_DIR}"
    rev-parse --short HEAD)

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
    else()
        set(_VERSION_SET FALSE)
    endif()
endmacro()

# Split "M", "M.N", "M.N.P" or "M.N.P.T" into three numeric components,
# defaulting absent ones to 0. A value that is not version-shaped at all
# degrades to 0.0.0 rather than emitting a field the compiler will reject.
macro(version_splitTriple _vst_value)
    set(_VERSION_TRIPLE_MAJOR 0)
    set(_VERSION_TRIPLE_MINOR 0)
    set(_VERSION_TRIPLE_PATCH 0)

    if("${_vst_value}" MATCHES "^v?([0-9]+)([._]([0-9]+))?([._]([0-9]+))?")
        set(_VERSION_TRIPLE_MAJOR "${CMAKE_MATCH_1}")

        if(NOT "${CMAKE_MATCH_3}" STREQUAL "")
            set(_VERSION_TRIPLE_MINOR "${CMAKE_MATCH_3}")
        endif()

        if(NOT "${CMAKE_MATCH_5}" STREQUAL "")
            set(_VERSION_TRIPLE_PATCH "${CMAKE_MATCH_5}")
        endif()
    endif()
endmacro()

# Populate the version fields from VERSION_FALLBACK when git supplied nothing
# parseable. The fields are assigned directly rather than composed into a
# synthetic tag and pushed back through version_parse_dispatch: a project that
# installed VERSION_PARSE_FUNCTION did so because its tags are *not* semver, so
# re-entering its parser could fail a second time and leave the header empty --
# the exact outcome this path exists to prevent.
macro(version_applyFallback _vaf_sha _vaf_commit _vaf_dirty)
    version_splitTriple("${VERSION_FALLBACK}")

    set(_VERSION_SET    TRUE)
    set(_VERSION_MAJOR  "${_VERSION_TRIPLE_MAJOR}")
    set(_VERSION_MINOR  "${_VERSION_TRIPLE_MINOR}")
    set(_VERSION_PATCH  "${_VERSION_TRIPLE_PATCH}")
    set(_VERSION_COMMIT "${_vaf_commit}")
    set(_VERSION_SHA    "${_vaf_sha}")
    set(_VERSION_DIRTY  "${_vaf_dirty}")
    set(_VERSION_SEMANTIC "${_VERSION_MAJOR}.${_VERSION_MINOR}.${_VERSION_PATCH}.${_VERSION_COMMIT}")

    # Mirror describe's own shape so consumers can parse VERSION_FULL uniformly
    # whether it came from a tag or from here. The "-g<sha>" segment is dropped
    # when there is no repository to read a commit from, rather than emitting a
    # dangling "-g" that looks like a truncated hash.
    set(_VERSION_FULL "${_VERSION_MAJOR}.${_VERSION_MINOR}.${_VERSION_PATCH}-${_VERSION_COMMIT}")

    if(NOT "${_vaf_sha}" STREQUAL "")
        string(APPEND _VERSION_FULL "-g${_vaf_sha}")
    endif()

    if(NOT "${_vaf_dirty}" STREQUAL "")
        string(APPEND _VERSION_FULL "-${_vaf_dirty}")
    endif()

    set(_VERSION_IS_FALLBACK TRUE)
endmacro()

# Dispatch to VERSION_PARSE_FUNCTION if set, otherwise use the built-in semver parser.
macro(version_parse_dispatch _vpd_ver)
    if(NOT "${VERSION_PARSE_FUNCTION}" STREQUAL "")
        cmake_language(CALL "${VERSION_PARSE_FUNCTION}" "${_vpd_ver}")
    else()
        version_parseSemantic("${_vpd_ver}")
    endif()
endmacro()

macro(version_export_variables)
    set(VERSION_SET      "${_VERSION_SET}"      CACHE INTERNAL "" FORCE)
    set(VERSION_IS_FALLBACK "${_VERSION_IS_FALLBACK}" CACHE INTERNAL "" FORCE)
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

set(_VERSION_SET FALSE)
set(_VERSION_IS_FALLBACK FALSE)

# Distinguishes "no tag matched, which is normal" from "a tag matched but did
# not parse, which is a misconfiguration". Drives the message severity below.
set(_VERSION_TAG_UNPARSEABLE FALSE)

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
    # Reported as RESULT_VARIABLE/ERROR_VARIABLE rather than "Result/Error": the
    # build-time re-invocation runs inside MSBuild, whose canonical-diagnostic
    # scraper reads a line containing "Error:'...'" as a compiler error and
    # fails the custom build step -- turning a recoverable fallback into a
    # broken build for anyone compiling outside a git checkout.
    message(CHECK_FAIL
        "Failed: ${GIT_VERSION_COMMAND}\nRESULT_VARIABLE:'${_GIT_RESULT}' \nERROR_VARIABLE:'${_GIT_ERROR}'")
    set(git_describe "")
    set(_VERSION_FALLBACK_REASON "git describe failed in '${VERSION_SOURCE_DIR}'")

    if("${_GIT_ERROR}" STREQUAL "fatal: bad revision 'HEAD'")
        set(_VERSION_FALLBACK_REASON "'${VERSION_SOURCE_DIR}' is not a readable git repository")
    endif()
else()
    message(CHECK_PASS "Success '${git_describe}'")

    message(CHECK_START "Parse version")
    version_parse_dispatch(${git_describe})

    if(_VERSION_SET)
        message(CHECK_PASS "Tag '${git_describe}' is a valid semantic version [${_VERSION_SEMANTIC}]")
        message(STATUS "Build date: ${VERSION_DATE}")
    elseif("${git_describe}" MATCHES "^[0-9A-Fa-f]+(-dirty)?$")
        # --long always emits "<tag>-<n>-g<sha>", so a bare commit id means
        # --always fired: no tag survived the --match/--exclude filters. This is
        # the ordinary state of a fresh clone or untagged branch and always
        # resolves via VERSION_FALLBACK below, so it is reported with
        # CHECK_PASS rather than CHECK_FAIL: a reader scanning for the failure
        # that broke their build should not stop here, since nothing failed
        # (issue #10b -- the diagnostic previously read as a failure even
        # though the header goes on to generate successfully).
        message(CHECK_PASS "No tag matching '${VERSION_TAG_PATTERN}' reachable from HEAD; using VERSION_FALLBACK")
        set(_VERSION_FALLBACK_REASON
            "no tag matching '${VERSION_TAG_PATTERN}' is reachable from HEAD")
    else()
        message(CHECK_FAIL "'${git_describe}' is not a valid semantic-version e.g. 'v0.1.2-30'")
        set(_VERSION_TAG_UNPARSEABLE TRUE)
        set(_VERSION_FALLBACK_REASON
            "describe selected '${git_describe}', which matches VERSION_TAG_PATTERN '${VERSION_TAG_PATTERN}' but does not parse as a version")
    endif()
endif()

# A header with empty version fields is worse than a build failure: it compiles,
# ships, and misreports the artifact. Anything git could not answer is filled in
# from VERSION_FALLBACK so every field is always populated.
if(NOT _VERSION_SET)
    message(CHECK_START "Fallback version")

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
        set(git_count 0)
    endif()

    execute_process(
        COMMAND ${GIT_SHA_COMMAND}
        RESULT_VARIABLE _GIT_RESULT
        OUTPUT_VARIABLE git_sha
        ERROR_VARIABLE  _GIT_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
        ${capture_output}
    )

    if(NOT _GIT_RESULT EQUAL 0)
        set(git_sha "")
    endif()

    if("${git_describe}" MATCHES "-dirty$")
        set(git_dirty "dirty")
    else()
        set(git_dirty "")
    endif()

    version_applyFallback("${git_sha}" "${git_count}" "${git_dirty}")
    set(git_describe "${_VERSION_FULL}")
    message(CHECK_PASS "${_VERSION_FULL} [${_VERSION_SEMANTIC}]")

    # Severity: an unparseable tag means VERSION_TAG_PATTERN and the parser
    # disagree -- a real configuration bug the maintainer can fix, and the one
    # that silently produced version-less builds. Everything else (no release
    # tagged yet, no git repository) is an ordinary state the developer already
    # knows about and cannot act on, so warning there would be unactionable
    # noise on every configure of every fresh clone.
    if(_VERSION_TAG_UNPARSEABLE)
        message(WARNING
            "Version.cmake: ${_VERSION_FALLBACK_REASON}. Using VERSION_FALLBACK '${VERSION_FALLBACK}' instead; "
            "set VERSION_TAG_PATTERN to match only tags your parser accepts.")
    else()
        message(STATUS
            "Version.cmake: ${_VERSION_FALLBACK_REASON}; using VERSION_FALLBACK '${VERSION_FALLBACK}'. "
            "VERSION_IS_FALLBACK is TRUE -- check it to fail a release build that has no tag.")
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
    set(VERSION_H "${VERSION_OUT_DIR}/${VERSION_H_FILENAME}")

    # VERSION_H_TEMPLATE: explicit escape hatch (issue #10a). A consumer may
    # pre-set this (as a normal variable, before include()) to an exact
    # template path, bypassing the VERSION_H_FILENAME naming convention
    # entirely. It is already forwarded verbatim into genCmakeVersion's
    # build-time re-invocation (-DVERSION_H_TEMPLATE=... below), so no further
    # plumbing is needed for it to survive there.
    if(DEFINED VERSION_H_TEMPLATE AND NOT "${VERSION_H_TEMPLATE}" STREQUAL "")
        message(CHECK_START "Find template")

        if(NOT EXISTS "${VERSION_H_TEMPLATE}")
            message(CHECK_FAIL "Not found")
            message(FATAL_ERROR
                "Version.cmake: VERSION_H_TEMPLATE '${VERSION_H_TEMPLATE}' does not exist")
        endif()

        message(CHECK_PASS "Using explicit VERSION_H_TEMPLATE '${VERSION_H_TEMPLATE}'")
    else()
        set(VERSION_H_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/${VERSION_H_FILENAME}.in")

        message(CHECK_START "Find '${VERSION_H_FILENAME}.in'")

        if(EXISTS "${VERSION_H_TEMPLATE}")
            message(CHECK_PASS "Found '${VERSION_H_TEMPLATE}'")
        else()
            # Exact filename missed. The shipped template is named
            # "Version.hpp.in", but documentation and consumer code have
            # historically referred to it as "version.hpp" -- on a
            # case-insensitive filesystem (Windows/macOS default) that discrepancy
            # is invisible, but on a case-sensitive one (Linux) or with any other
            # differently-cased reference, the exact-match EXISTS check above
            # misses silently and this used to fall straight through to
            # auto-generating the wrong (C-only) template with no error at all
            # (issue #10a). Before concluding no template exists, do a
            # case-insensitive scan of the same directory.
            string(TOLOWER "${VERSION_H_FILENAME}.in" _VERSION_H_TEMPLATE_LOWER)
            file(GLOB _VERSION_H_TEMPLATE_CANDIDATES LIST_DIRECTORIES FALSE
                "${CMAKE_CURRENT_LIST_DIR}/*.in")
            set(_VERSION_H_TEMPLATE_MATCH "")

            foreach(_VERSION_H_TEMPLATE_CANDIDATE IN LISTS _VERSION_H_TEMPLATE_CANDIDATES)
                get_filename_component(_VERSION_H_TEMPLATE_CANDIDATE_NAME
                    "${_VERSION_H_TEMPLATE_CANDIDATE}" NAME)
                string(TOLOWER "${_VERSION_H_TEMPLATE_CANDIDATE_NAME}" _VERSION_H_TEMPLATE_CANDIDATE_LOWER)

                if("${_VERSION_H_TEMPLATE_CANDIDATE_LOWER}" STREQUAL "${_VERSION_H_TEMPLATE_LOWER}")
                    set(_VERSION_H_TEMPLATE_MATCH "${_VERSION_H_TEMPLATE_CANDIDATE}")
                    break()
                endif()
            endforeach()
            unset(_VERSION_H_TEMPLATE_CANDIDATE)
            unset(_VERSION_H_TEMPLATE_CANDIDATE_NAME)
            unset(_VERSION_H_TEMPLATE_CANDIDATE_LOWER)

            if(NOT "${_VERSION_H_TEMPLATE_MATCH}" STREQUAL "")
                set(VERSION_H_TEMPLATE "${_VERSION_H_TEMPLATE_MATCH}")
                message(CHECK_PASS
                    "Found '${VERSION_H_TEMPLATE}' (case-insensitive match for "
                    "'${VERSION_H_FILENAME}.in' -- for portability to case-sensitive "
                    "filesystems, match the case exactly or set VERSION_H_TEMPLATE explicitly)")
            else()
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
            endif()
        endif()
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
            "-DVERSION_SOURCE_DIR=${VERSION_SOURCE_DIR}"
            "-DVERSION_PARSE_FUNCTION=${VERSION_PARSE_FUNCTION}"
            "-DVERSION_PARSE_MODULE=${VERSION_PARSE_MODULE}"
            # The tag filters and the fallback must be forwarded too: this is a
            # fresh `cmake -P` process with no project() and no cache, so an
            # unforwarded VERSION_FALLBACK would silently re-default to 0.0.0
            # and the built header would disagree with the configure-time one.
            "-DVERSION_TAG_PATTERN=${VERSION_TAG_PATTERN}"
            "-DVERSION_TAG_EXCLUDE_PATTERN=${VERSION_TAG_EXCLUDE_PATTERN}"
            "-DVERSION_FALLBACK=${VERSION_FALLBACK}"
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

# VERSION_IS_FALLBACK is reported here so a reader of the configure log can see
# at a glance that the version came from VERSION_FALLBACK and not from a tag.
if(VERSION_IS_FALLBACK)
    set(_VERSION_ORIGIN ", fallback")
else()
    set(_VERSION_ORIGIN "")
endif()

if(NOT VERSION_SET)
    message(CHECK_FAIL "Version.cmake failed - VERSION_SET==false")
elseif(VERSION_H_GENERATED)
    message(CHECK_PASS "${VERSION_FULL} [${VERSION_SEMANTIC}] {Generated${_VERSION_ORIGIN}}")
elseif(EXISTS "${VERSION_H}")
    message(CHECK_PASS "Using pre-defined '${VERSION_H}'")
else()
    message(CHECK_FAIL "Failed, ${VERSION_H} not available")
endif()
