# @note 3.20 required for `GENERATED` attribute to be project-wide i.e. Version.h isn't build until build-time
cmake_minimum_required(VERSION 3.20)

# We support Version.cmake usage before `project(...) when crossCompiling
# - Todo this we must avoid calling project() as Cmake will setup compiler at this time
get_directory_property(hasParent PARENT_DIRECTORY)
if ( NOT hasParent OR PROJECT_IS_TOP_LEVEL)
	project(Version.cmake)
endif()

include(cmake/Version.cmake)