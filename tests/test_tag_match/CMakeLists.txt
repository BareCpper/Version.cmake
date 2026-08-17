cmake_minimum_required(VERSION 3.20)

# The project version is deliberately unlike the tag version. If tag selection
# regresses and the fallback fires instead, the assertions below see 9.9.9 and
# fail loudly rather than passing on a plausible-looking number.
project(test_tag_match VERSION 9.9.9 LANGUAGES NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../TestSupport.cmake")

# Verify: describe reaches past both kinds of unusable tag to the real release
# tag, exercising the --match and --exclude filters together.
#
#   perfgate-pre-recovery -- rejected by --match. Tagging before a risky git
#       operation is common enough that describe picking such a tag left real
#       builds with every version field empty.
#   v1.2.3-40 -- rejected by --exclude. A 'tweak' tag whose trailing "-40"
#       collides with describe's own "-<commits>-g<sha>" suffix, so it does not
#       parse either. It matches VERSION_TAG_PATTERN, so only --exclude keeps it
#       out: dropping --exclude when --match was added would fail here.
#
# Both sit on the newest commit, so either one winning changes the result.
set(REPO "${CMAKE_BINARY_DIR}/repo")
version_test_gitInit("${REPO}")
version_test_gitCommit("${REPO}" "release")
version_test_gitTag("${REPO}" "v1.2.3")
version_test_gitCommit("${REPO}" "work")
version_test_gitCommit("${REPO}" "more work")
version_test_gitTag("${REPO}" "perfgate-pre-recovery")
version_test_gitTag("${REPO}" "v1.2.3-40")

set(VERSION_SOURCE_DIR "${REPO}")

include("${VERSION_CMAKE_DIR}/Version.cmake")

if(NOT VERSION_SET)
    message(FATAL_ERROR "VERSION_SET is false -- version parsing failed")
endif()

if(VERSION_IS_FALLBACK)
    message(FATAL_ERROR
        "fell back to '${VERSION_FALLBACK}'; expected the v1.2.3 tag to be selected over 'perfgate-pre-recovery' and 'v1.2.3-40'")
endif()

version_test_assertEqual("VERSION_SEMANTIC" "${VERSION_SEMANTIC}" "1.2.3.2")
version_test_assertEqual("VERSION_MAJOR"    "${VERSION_MAJOR}"    "1")
version_test_assertEqual("VERSION_MINOR"    "${VERSION_MINOR}"    "2")
version_test_assertEqual("VERSION_PATCH"    "${VERSION_PATCH}"    "3")
version_test_assertEqual("VERSION_COMMIT"   "${VERSION_COMMIT}"   "2")

file(WRITE "${CMAKE_BINARY_DIR}/generated_header.txt" "${VERSION_H}")
