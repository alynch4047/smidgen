cmake_minimum_required (VERSION 2.8)

add_subdirectory(smidgen)

set(EXTRA_LIBS_DIR ${CMAKE_SOURCE_DIR}/libs)
set(SMIDGEN_SOURCES ${CMAKE_SOURCE_DIR}/src)


add_custom_target(smidgen ALL
             COMMAND ${RDMD_EXECUTABLE} ${RDMD_BUILD_ONLY} ${MAKE_DOCS}
             -I${EXTRA_LIBS_DIR} -I${SMIDGEN_SOURCES} 
             -J${SMIDGEN_SOURCES}/smidgen -of${CMAKE_INSTALL_PREFIX}/smidgen
             ${SMIDGEN_SOURCES}/smidgen/make_wrapping.d)


ENABLE_TESTING()  

add_test(TestSmidgen ${RDMD_EXECUTABLE} -I${EXTRA_LIBS_DIR} -I${SMIDGEN_SOURCES} 
                -J${CMAKE_CURRENT_SOURCE_DIR}/smidgen/test
             ${CMAKE_CURRENT_SOURCE_DIR}/smidgen/test/tst.d )


