# MIT License
# Copyright (c) 2022 craig-barecpper@crog.uk
# Distributed under the MIT License. See accompanying LICENSE or https://cmake.org/licensing for details.

# @note 3.20 required for `GENERATED` attribute to be project-wide i.e. Version.h isn't build until build-time
cmake_minimum_required(VERSION 3.20)

#TODO? if ( DEFINED VERSION_SEMANTIC )
    #return()
#endif()

message(CHECK_START "GitVersion")
list(APPEND CMAKE_MESSAGE_INDENT "  ")

set(VERSION_H_DIR "${CMAKE_BINARY_DIR}")
set(GIT_CACHE_DIR "${CMAKE_SOURCE_DIR}/.git")

# TODO: We generate the .H as a separate build-target
if( DEFINED GIT_VERSION_DST )
    set(GITVERSION_DO_CONFIGURE TRUE)
    message(CHECK_PASS "Do Configure GitVersion")
endif()

# Get gitVersion information
message(CHECK_START "Find git")
if( NOT DEFINED GIT_EXECUTABLE ) # Find Git or bail out
    find_package( Git )
    if( NOT Git_FOUND )
        message(CHECK_FAIL "Not found in PATH")
    else()
        message(CHECK_PASS "Found: '${GIT_EXECUTABLE}'")
    endif()
else()
    message(CHECK_PASS "Using pre-defined GIT_EXECUTABLE: '${GIT_EXECUTABLE}'")
endif()
    
# Git describe
# @note Exclude 'tweak' tags in the form v0.1.2-30 i.e. with the '-30' to avoid a second suffix being appended e.g v0.1.2-30-12
set(GIT_VERSION_COMMAND "${GIT_EXECUTABLE}"-C "${CMAKE_CURRENT_SOURCE_DIR}"--no-pager describe --tags --exclude "v[0-9]*.[0-9]*.[0-9]*-[0-9]*"--always --dirty --long)

# Git count
# @note We only count commits on the current branch and not comits in merge branches via '--first-parent'. The count is never unique but the Sha will be!
set(GIT_COUNT_COMMAND "${GIT_EXECUTABLE}"-C "${CMAKE_CURRENT_SOURCE_DIR}"rev-list HEAD --count  --first-parent)

macro(parseSemanticVersion semVer)
    if( "${semVer}"MATCHES "^v?([0-9]+)[.]([0-9]+)[.]?([0-9]+)?[-]([0-9]+)[-][g]([.0-9A-Fa-f]+)[-]?(dirty)?$")
        set( VERSON_SET TRUE)
        math( EXPR VERSION_MAJOR "${CMAKE_MATCH_1}+0" OUTPUT_FORMAT DECIMAL)
        math( EXPR VERSION_MINOR "${CMAKE_MATCH_2}+0" OUTPUT_FORMAT DECIMAL)
        math( EXPR VERSION_PATCH "${CMAKE_MATCH_3}+0" OUTPUT_FORMAT DECIMAL)
        math( EXPR VERSION_COMMIT "${CMAKE_MATCH_4}+0"OUTPUT_FORMAT DECIMAL)
        set( VERSION_SHA   "${CMAKE_MATCH_5}")
        set( VERSION_DIRTY "${CMAKE_MATCH_6}")
        set( VERSION_SEMANTIC ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}.${VERSION_COMMIT} )    
        set( VERSION_FULL ${git_describe} )
    else()
        set( VERSON_SET FALSE)
    endif()
endmacro()

message(CHECK_START "Git-Describe")
execute_process(
    COMMAND           ${GIT_VERSION_COMMAND}
    RESULT_VARIABLE   git_result
    OUTPUT_VARIABLE   git_describe
    ERROR_VARIABLE    git_error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    ${capture_output}
)
if( NOT git_result EQUAL 0 )
    message( CHECK_FAIL "Failed: ${GIT_VERSION_COMMAND}\nRESULT_VARIABLE:'${git_result}' \nOUTPUT_VARIABLE:'${git_describe}' \nERROR_VARIABLE:'${git_error}'")
else()
    message(CHECK_PASS "Success '${git_describe}'")

    message(CHECK_START "Parse version")
    parseSemanticVersion(${git_describe})
    if( ${VERSON_SET} )
        message(CHECK_PASS "Tag '${git_describe} is a valid semantic version [${VERSION_SEMANTIC}]")
    else()
        message(CHECK_FAIL "'${git_describe}' is not a valid semantic-version e.g. 'v0.1.2-30'")
    endif()
endif()
    
if(NOT DEFINED VERSION_FULL)
    message(CHECK_START "Fallback as Git-Count")
    execute_process(
        COMMAND           ${GIT_COUNT_COMMAND}
        RESULT_VARIABLE   git_result
        OUTPUT_VARIABLE   git_count
        ERROR_VARIABLE    git_error
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
        ${capture_output}
    )
    if( NOT git_result EQUAL 0 )
        message( CHECK_FAIL "Failed: ${GIT_VERSION_COMMAND}\nRESULT_VARIABLE:'${git_result}' \nOUTPUT_VARIABLE:'${git_count}' \nERROR_VARIABLE:'${git_error}'")
    else()    
        set(git_describe "0.0.0-${git_count}-g${git_describe}")
        parseSemanticVersion(${git_describe})
        if( ${VERSON_SET} )
            message(CHECK_PASS "git-tag '${git_describe} is a valid semantic version")
        else()
            message(CHECK_FAIL "'${git_describe}' is not a valid semantic-version e.g. 'v0.1.2-30'")
        endif()
    endif()

   # message( STATUS "Git Commit-Count '${VERSION_FULL}'")
endif()


function(gitversion_configure_file GIT_VERSION_SRC GIT_VERSION_DST) 
    message( "VERSION_SEMANTIC ${VERSION_SEMANTIC}")
    message( "VERSION_FULL ${VERSION_FULL}")

    configure_file (
        "${GIT_VERSION_SRC}"
        "${GIT_VERSION_DST}"
    )
endfunction()

if ( GITVERSION_DO_CONFIGURE )
    gitversion_configure_file( ${GIT_VERSION_SRC} ${GIT_VERSION_DST})
else() 
    set(GIT_VERSION_SRC "${CMAKE_CURRENT_LIST_DIR}/Version.h.in")
    set(GIT_VERSION_DST "${VERSION_H_DIR}/Version.h")

    # If no Version.h.in exists we generate the template witht eh default
    message(CHECK_START "Find 'Version.h.in'")
    if ( NOT EXISTS ${GIT_VERSION_SRC} )
        set(GIT_VERSION_SRC "${CMAKE_CURRENT_BINARY_DIR}/Version.h.in")
        message( CHECK_FAIL "Not Found. Generating '${GIT_VERSION_SRC}'")

        file(WRITE ${GIT_VERSION_SRC}
      [=[
#define VERSION_MAJOR @VERSION_MAJOR@
#define VERSION_MINOR @VERSION_MINOR@
#define VERSION_PATCH @VERSION_PATCH@
#define VERSION_COMMIT @VERSION_COMMIT@
#define VERSION_SEMANTIC "@VERSION_SEMANTIC@"
#define VERSION_FULL "@VERSION_FULL@"
      ]=])
    else()
        message( CHECK_PASS "Found '${GIT_VERSION_SRC}'")
    endif()

    # A custom target is used to update Version.h
    add_custom_target( genGitVersion
        ALL
        BYPRODUCTS "${VERSION_H_DIR}/Version.h"
        SOURCES "${GIT_VERSION_SRC}"
        DEPENDS "${GIT_CACHE_DIR}/index"
            "${GIT_CACHE_DIR}/HEAD"
        COMMENT "GitVersion: Generating Version.h"
        COMMAND ${CMAKE_COMMAND}            
            -B "${CMAKE_CURRENT_BINARY_DIR}"
            -D GIT_VERSION_SRC="${GIT_VERSION_SRC}"
            -D GIT_VERSION_DST="${GIT_VERSION_DST}"
            -D GIT_EXECUTABLE="${GIT_EXECUTABLE}"
            -D CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH} 
            -P "${CMAKE_CURRENT_LIST_FILE}" 
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"       
    )

    add_library( gitVersion INTERFACE )
    target_include_directories(gitVersion INTERFACE "${VERSION_H_DIR}")

    # @note Explicit file-names - prevent Cmake finding `Version.h.in` for `Version.h`
    if (POLICY CMP0115)
        cmake_policy(SET CMP0115 NEW)
    endif()

    target_sources( gitVersion 
        INTERFACE 
            "${VERSION_H_DIR}/Version.h")
    add_dependencies( gitVersion 
        INTERFACE genGitVersion )
        
    add_library( git::version ALIAS gitVersion )
endif()

list(POP_BACK CMAKE_MESSAGE_INDENT)
if(EXISTS ${GIT_VERSION_DST})
  message(CHECK_PASS "${VERSION_FULL} [${VERSION_SEMANTIC}]")
else()
  message(CHECK_FAIL "Failed, ${GIT_VERSION_DST} not available")
endif()