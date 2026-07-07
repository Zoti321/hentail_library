# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "hentai_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
get_filename_component(PLUGIN_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." REALPATH)
apply_cargokit(${PROJECT_NAME} ../rust hentai_flutter "")

# List of absolute paths to libraries that should be bundled with the plugin.
set(hentai_flutter_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
)

get_filename_component(VENDOR_ROOT "${PLUGIN_ROOT}/../../core/vendor/windows-x86_64" REALPATH)
set(PDFIUM_DLL "${VENDOR_ROOT}/pdfium.dll")
if(EXISTS "${PDFIUM_DLL}")
  list(APPEND hentai_flutter_bundled_libraries "${PDFIUM_DLL}")
endif()

set(hentai_flutter_bundled_libraries "${hentai_flutter_bundled_libraries}" PARENT_SCOPE)
