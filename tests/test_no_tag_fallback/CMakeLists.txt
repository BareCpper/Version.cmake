cmake_minimum_required(VERSION 3.20)

# The fallback's source: with no usable tag the build must report the number the
# maintainer wrote down here.
project(test_no_tag_fallback VERSION 4.5.6 LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../TestSupport.cmake")

# Verify: a repository with no tag matching VERSION_TAG_PATTERN still produces a
# fully populated header. An empty header is worse than a failed build -- it
# compiles, ships, and misreports the artifact's version as nothing at all.
#
# The lone tag is not version-shaped, so this also covers the ordinary state of
# a fresh clone that has never been released.
set(REPO "${CMAKE_BINARY_DIR}/repo")
version_test_gitInit("${REPO}")
version_test_gitCommit("${REPO}" "initial")
version_test_gitCommit("${REPO}" "work")
version_test_gitTag("${REPO}" "silentfail-pre-cleanup")

set(VERSION_SOURCE_DIR "${REPO}")

include("${VERSION_CMAKE_DIR}/Version.cmake")

if(NOT VERSION_SET)
    message(FATAL_ERROR "VERSION_SET is false -- the fallback must always produce a version")
endif()

if(NOT VERSION_IS_FALLBACK)
    message(FATAL_ERROR "VERSION_IS_FALLBACK is false, but no tag matched '${VERSION_TAG_PATTERN}'")
endif()

# VERSION_FALLBACK defaults to PROJECT_VERSION, so these are the project()
# components with the commit count carried over from git.
version_test_assertEqual("VERSION_SEMANTIC" "${VERSION_SEMANTIC}" "4.5.6.2")
version_test_assertEqual("VERSION_MAJOR"    "${VERSION_MAJOR}"    "4")
version_test_assertEqual("VERSION_MINOR"    "${VERSION_MINOR}"    "5")
version_test_assertEqual("VERSION_PATCH"    "${VERSION_PATCH}"    "6")
version_test_assertEqual("VERSION_COMMIT"   "${VERSION_COMMIT}"   "2")

# The commit is still identified even though no tag named it.
if("${VERSION_SHA}" STREQUAL "")
    message(FATAL_ERROR "VERSION_SHA is empty; the fallback should still identify HEAD")
endif()

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
