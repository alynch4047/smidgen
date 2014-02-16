cmake_minimum_required (VERSION 2.8)
project(SMIDGEN)

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/install)

set(RDMD_EXECUTABLE rdmd)
set(RDMD_BUILD_ONLY --build-only)
set(MAKE_DOCS -Dd${CMAKE_SOURCE_DIR}/docs)

add_subdirectory(src)
add_subdirectory(morsel)
add_subdirectory(morseld)

ENABLE_TESTING()  
