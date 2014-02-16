cmake_minimum_required (VERSION 2.8)

project(morsel CXX)

include_directories (${CMAKE_CURRENT_SOURCE_DIR}/h) 

add_library (morsel SHARED ${CMAKE_CURRENT_SOURCE_DIR}/cpp/rect.cpp
                           ${CMAKE_CURRENT_SOURCE_DIR}/cpp/shape.cpp
                           ${CMAKE_CURRENT_SOURCE_DIR}/cpp/point.cpp
                           ${CMAKE_CURRENT_SOURCE_DIR}/cpp/polygon.cpp
                           ${CMAKE_CURRENT_SOURCE_DIR}/cpp/widget.cpp
                           ${CMAKE_CURRENT_SOURCE_DIR}/cpp/rect_widget.cpp
                           ${CMAKE_CURRENT_SOURCE_DIR}/cpp/calculator.cpp) 

add_executable(trymorsel ${CMAKE_CURRENT_SOURCE_DIR}/cpp/try_morsel.cpp)

target_link_libraries (trymorsel morsel) 

install(TARGETS morsel
        DESTINATION libs)
