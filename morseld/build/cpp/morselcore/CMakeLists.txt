
cmake_minimum_required (VERSION 2.8)

include_directories (${CMAKE_SOURCE_DIR}/morsel/h ${CMAKE_CURRENT_SOURCE_DIR})

add_library (morselcorewrapper SHARED ${CMAKE_CURRENT_SOURCE_DIR}/Rect_wrapper.cpp 
                            ${CMAKE_CURRENT_SOURCE_DIR}/Shape_wrapper.cpp
                            ${CMAKE_CURRENT_SOURCE_DIR}/Point_wrapper.cpp
                            ${CMAKE_CURRENT_SOURCE_DIR}/Point_Place_wrapper.cpp
                            ${CMAKE_CURRENT_SOURCE_DIR}/Polygon_wrapper.cpp
                            ${CMAKE_CURRENT_SOURCE_DIR}/Calculator_wrapper.cpp
                            ${CMAKE_CURRENT_SOURCE_DIR}/package_wrapper.cpp
                            ${CMAKE_CURRENT_SOURCE_DIR}/instance_tracker.cpp )
                           
add_dependencies(morselcorewrapper morsel_generate)

target_link_libraries (morselcorewrapper morsel)

install(TARGETS morselcorewrapper
        DESTINATION libs)