
cmake_minimum_required (VERSION 2.8)

include_directories (${CMAKE_SOURCE_DIR}/morsel/h ${CMAKE_CURRENT_SOURCE_DIR})

add_library (morselwidgetwrapper SHARED
                    ${CMAKE_CURRENT_SOURCE_DIR}/Widget_wrapper.cpp
                    ${CMAKE_CURRENT_SOURCE_DIR}/RectWidget_wrapper.cpp
                    ${CMAKE_CURRENT_SOURCE_DIR}/package_wrapper.cpp
                    ${CMAKE_CURRENT_SOURCE_DIR}/instance_tracker.cpp )
                           
add_dependencies(morselwidgetwrapper morsel_generate)

target_link_libraries (morselwidgetwrapper morsel)

install(TARGETS morselwidgetwrapper
        DESTINATION libs)