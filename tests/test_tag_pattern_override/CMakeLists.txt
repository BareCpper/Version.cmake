cmake_minimum_required(VERSION 3.20)

# Unlike the tag version, so a silent fallback cannot pass this test.
project(test_tag_pattern_override VERSION 9.9.9 LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../TestSupport.cmake")

# Verify: VERSION_TAG_PATTERN adapts the default 'v'-prefixed convention to a
# project that tags without the prefix, and a list value expands to one --match
# flag per element. Passing the list as a single glob would match nothing here
# and drop to the fallback, so the assertions discriminate between the two.
#
# The newest tag is again not version-shaped, so an overridden pattern still has
# to filter rather than merely widen what describe will accept.
set(REPO "${CMAKE_BINARY_DIR}/repo")
version_test_gitInit("${REPO}")
version_test_gitCommit("${REPO}" "release")
version_test_gitTag("${REPO}" "1.4.0")
version_test_gitCommit("${REPO}" "work")
version_test_gitTag("${REPO}" "nightly-green")

set(VERSION_TAG_PATTERN "v[0-9]*;[0-9]*")

set(VERSION_SOURCE_DIR "${REPO}")

include("${VERSION_CMAKE_DIR}/Version.cmake")

if(NOT VERSION_SET)
    message(FATAL_ERROR "VERSION_SET is false -- version parsing failed")
endif()

if(VERSION_IS_FALLBACK)
    message(FATAL_ERROR
        "fell back to '${VERSION_FALLBACK}'; expected VERSION_TAG_PATTERN '${VERSION_TAG_PATTERN}' to select the 1.4.0 tag")
endif()

version_test_assertEqual("VERSION_SEMANTIC" "${VERSION_SEMANTIC}" "1.4.0.1")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
