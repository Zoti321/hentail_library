# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "hentai_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
get_filename_component(PLUGIN_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." REALPATH)
get_filename_component(RUST_CRATE_DIR "${PLUGIN_ROOT}/../../core/crates/flutter" REALPATH)
file(RELATIVE_PATH RUST_CRATE_REL "${CMAKE_CURRENT_SOURCE_DIR}" "${RUST_CRATE_DIR}")
apply_cargokit(${PROJECT_NAME} "${RUST_CRATE_REL}" hentai_flutter "")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(hentai_flutter_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
