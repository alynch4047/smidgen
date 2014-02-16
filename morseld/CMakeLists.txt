cmake_minimum_required (VERSION 2.8)

project(morseld CXX)

add_subdirectory(build)
add_subdirectory(test)

set(SMIDGEN_EXE ${CMAKE_CURRENT_SOURCE_DIR}/../install/smidgen)

add_custom_target(morsel_generate ALL
#             COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_SOURCE_DIR}/build/cpp
#             COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_SOURCE_DIR}/build/d
#             COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_SOURCE_DIR}/build/cpp
#             COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_SOURCE_DIR}/build/d
#             COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CPPCMakeLists.txt
#                                          ${CMAKE_CURRENT_SOURCE_DIR}/build/cpp/CMakeLists.txt
             COMMAND ${SMIDGEN_EXE} 
                 ${CMAKE_CURRENT_SOURCE_DIR}/sip/morsel.sip
                 ${CMAKE_CURRENT_SOURCE_DIR}/build
             
             DEPENDS smidgen)
             

ENABLE_TESTING()  


