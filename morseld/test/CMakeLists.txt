cmake_minimum_required (VERSION 2.8)

set(MORSEL_BUILD ${CMAKE_SOURCE_DIR}/morseld/build)

set(MORSEL_WRAPPER_LIBS ${CMAKE_SOURCE_DIR}/install/libs)

set(DMD_I_DIR ${MORSEL_BUILD}/d)
set(DMD_J_DIR ${MORSEL_BUILD}/d/morselcore)
set(DMD_L_DIR ${MORSEL_BUILD}/cpp)
set(DMD_L_DIR_CORE ${MORSEL_BUILD}/cpp/morselcore/libmorselcorewrapper.so)
set(DMD_L_DIR_WIDGET ${MORSEL_BUILD}/cpp/morselwidget/libmorselwidgetwrapper.so)

add_custom_target(morselmemory ALL
   COMMAND env LD_LIBRARY_PATH=${MORSEL_WRAPPER_LIBS} ${RDMD_EXECUTABLE} -gc -debug ${RDMD_BUILD_ONLY}
            -I${DMD_I_DIR}
            -J${DMD_J_DIR}
            -L${DMD_L_DIR_CORE}
             ${CMAKE_CURRENT_SOURCE_DIR}/test_morsel_memory.d
    DEPENDS morsel_generate
           )  
           
add_custom_target(usemorsel ALL
   COMMAND env LD_LIBRARY_PATH=${MORSEL_WRAPPER_LIBS} ${RDMD_EXECUTABLE} -gc -debug ${RDMD_BUILD_ONLY}
            -I${DMD_I_DIR}
            -J${DMD_J_DIR}
            -L${DMD_L_DIR_CORE}
            -L${DMD_L_DIR_WIDGET}
             ${CMAKE_CURRENT_SOURCE_DIR}/use_morsel.d
    DEPENDS morsel_generate
           )             

ENABLE_TESTING()

add_test(TestMorselMemory  env LD_LIBRARY_PATH=${MORSEL_WRAPPER_LIBS} ${RDMD_EXECUTABLE} 
            -I${DMD_I_DIR}
            -J${DMD_J_DIR}
            -L${DMD_L_DIR_CORE}
             ${CMAKE_CURRENT_SOURCE_DIR}/test_morsel_memory.d)    

add_test(TestUseMorsel env LD_LIBRARY_PATH=${MORSEL_WRAPPER_LIBS} ${RDMD_EXECUTABLE} -gc -debug
            -I${DMD_I_DIR}
            -J${DMD_J_DIR}
            -L${DMD_L_DIR_CORE}
            -L${DMD_L_DIR_WIDGET}
             ${CMAKE_CURRENT_SOURCE_DIR}/use_morsel.d)  
            
             
             