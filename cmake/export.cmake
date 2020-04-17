cmake_policy(PUSH)

if (NOT API_NAME)
    message(ERROR "Set API_NAME variable before to use export.cmake")
endif ()

set(${API_NAME}_SHARED_LIBRARY ${BUILD_SHARED_LIBS})
set(CMAKE_DEFINE "#cmakedefine")

configure_file(${CMAKE_CURRENT_LIST_DIR}/../res/export_configuration.h.in.in ${CMAKE_CURRENT_BINARY_DIR}/res/export_configuration.h.in @ONLY)
configure_file(${CMAKE_CURRENT_BINARY_DIR}/res/export_configuration.h.in ${CMAKE_CURRENT_BINARY_DIR}/neuon/export_configuration.h @ONLY)

cmake_policy(POP)
