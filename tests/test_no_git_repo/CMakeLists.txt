cmake_minimum_required(VERSION 3.20)

# The fallback's source for a tree with no history at all.
project(test_no_git_repo VERSION 7.8.9 LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../TestSupport.cmake")

# Verify: an unpacked source archive -- no .git anywhere above it -- still
# configures, and still produces a fully populated header.
#
# VERSION_SOURCE_DIR points at a directory created for this test rather than at
# the test's own source dir, which sits inside the Version.cmake checkout and
# would find that repository's history. The test's GIT_CEILING_DIRECTORIES stops
# git ascending out of the build tree into that same checkout.
set(NOREPO "${CMAKE_BINARY_DIR}/no_repo")
file(REMOVE_RECURSE "${NOREPO}")
file(MAKE_DIRECTORY "${NOREPO}")

set(VERSION_SOURCE_DIR "${NOREPO}")

include("${VERSION_CMAKE_DIR}/Version.cmake")

if(NOT VERSION_SET)
    message(FATAL_ERROR "VERSION_SET is false -- a tree with no git history must still get a version")
endif()

if(NOT VERSION_IS_FALLBACK)
    message(FATAL_ERROR "VERSION_IS_FALLBACK is false, but there is no repository to read")
endif()

# No commit to name, so VERSION_FULL must not carry a dangling "-g" marker.
version_test_assertEqual("VERSION_SEMANTIC" "${VERSION_SEMANTIC}" "7.8.9.0")
version_test_assertEqual("VERSION_SHA"      "${VERSION_SHA}"      "")
version_test_assertEqual("VERSION_FULL"     "${VERSION_FULL}"     "7.8.9-0")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
