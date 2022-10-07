# @note 3.20 required for `GENERATED` attribute to be project-wide i.e. Version.h isn't build until build-time
cmake_minimum_required(VERSION 3.20)

project(Version.cmake)

include(cmake/Version.cmake)