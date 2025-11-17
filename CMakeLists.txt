cmake_minimum_required(VERSION 3.21)

set(MEMENTOR_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake" CACHE INTERNAL "Path to custom CMake modules to use by parent projects")
list(APPEND CMAKE_MODULE_PATH ${MEMENTOR_MODULE_PATH})

include(GenerateSemanticVersionHeader)
set_semantic_version_variables(NAMESPACE mementor)

project(mementor VERSION ${MEMENTOR_VERSION} LANGUAGES CXX)
message(STATUS "Build ${PROJECT_NAME}-${MEMENTOR_VERSION_LONG} at ${MEMENTOR_TIMESTAMP} on ${CMAKE_SYSTEM_NAME}")

enable_testing()

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

include(GenerateSymbolExportHeader)
generate_symbol_export_header(NAMESPACE mementor)
generate_semantic_version_header(NAMESPACE mementor)

find_package(FFMPEG 4.3.2 EXACT REQUIRED COMPONENTS avcodec avformat swscale swresample)
find_package(Boost REQUIRED COMPONENTS headers date_time program_options filesystem log log_setup)
find_package(CURL REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(GTest 1.8 CONFIG REQUIRED COMPONENTS gtest gmock gmock_main )

include(GoogleTest)

find_package(PkgConfig)
if (PkgConfig_FOUND)
    pkg_check_modules(UUID libuuid)
endif ()

add_library(mementor INTERFACE)
add_library(mementor::mementor ALIAS mementor)

add_library(singleton OBJECT)
add_library(mementor::singleton ALIAS singleton)
target_sources(singleton
    PRIVATE
        src/singleton.cpp
    PUBLIC
        FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
            FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/singleton.h
)
target_include_directories(singleton
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

add_library(sighandler INTERFACE)
add_library(mementor::sighandler ALIAS sighandler)
target_sources(singleton
    PUBLIC
        FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
            FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/sighandler.h
)
target_include_directories(sighandler
    INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

add_library(hash_fnv1a OBJECT)
add_library(mementor::hash_fnv1a ALIAS hash_fnv1a)
target_sources(hash_fnv1a
    PRIVATE
        src/hash_fnv1a.cpp
    PUBLIC
        FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
            FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/hash_fnv1a.h
)
target_include_directories(hash_fnv1a
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

add_executable(ut_hash_fnv1a
    test/ut_hash_fnv1a.cpp
)
target_link_libraries(ut_hash_fnv1a PRIVATE GTest::gtest GTest::gmock_main hash_fnv1a)
gtest_discover_tests(ut_hash_fnv1a)

add_library(interruption OBJECT)
add_library(mementor::interruption ALIAS interruption)
target_sources(interruption
    PRIVATE
        src/interruption.cpp
    PUBLIC
        FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
            FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/interruption.h
)
target_include_directories(interruption
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

add_executable(ut_interruption
    test/ut_interruption.cpp
)
target_link_libraries(ut_interruption PRIVATE GTest::gtest GTest::gmock_main interruption)
gtest_discover_tests(ut_interruption)

if(UUID_FOUND)
    add_library(uuid INTERFACE)
    add_library(mementor::uuid ALIAS uuid)
    target_sources(uuid
        PRIVATE
            src/uuid.cpp
        PUBLIC
            FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
                FILES ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/uuid.h>
    )
    target_include_directories(uuid
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
endif()

if(CURL_FOUND)
    add_library(curl OBJECT)
    add_library(mementor::curl ALIAS curl)
    target_sources(curl
        PRIVATE
            src/curl.cpp
        PUBLIC
            FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
                FILES
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/curl.h
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/http_error_code.h
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/response.h
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/transport_error.h
    )
    target_include_directories(curl
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
    target_link_libraries(curl PUBLIC CURL::libcurl)

    add_executable(ut_curl
        test/ut_curl.cpp
        )
    target_link_libraries(ut_curl PRIVATE GTest::gmock GTest::gmock_main curl)
    gtest_discover_tests(ut_curl)
endif()

if(Boost_FOUND)
    add_library(ntp OBJECT)
    add_library(mementor::ntp ALIAS ntp)
    target_sources(ntp
        PRIVATE
            src/ntp.cpp
        PUBLIC
            FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
                FILES
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/ntp.h
    )
    target_link_libraries(ntp PUBLIC Boost::date_time)
    target_include_directories(ntp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )

    add_executable(ut_ntp
        test/ut_ntp.cpp
    )
    target_link_libraries(ut_ntp PRIVATE GTest::gtest GTest::gmock_main Boost::date_time ntp)
    gtest_discover_tests(ut_ntp)

    add_library(options OBJECT)
    add_library(mementor::options ALIAS options)
    target_sources(options
        PRIVATE
            src/options.cpp
        PUBLIC
            FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
                FILES
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/options.h
    )
    target_include_directories(options
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
    target_link_libraries(options PUBLIC Boost::program_options )

    add_executable(ut_options
        test/ut_options.cpp
    )
    target_link_libraries(ut_options PRIVATE GTest::gtest GTest::gmock_main options)
    gtest_discover_tests(ut_options)
endif()

if(NOT ${CMAKE_HOST_WIN32} AND Boost_FOUND AND spdlog_FOUND)
    add_library(external_tool OBJECT)
    add_library(mementor::external_tool ALIAS external_tool)
    target_sources(external_tool
        PRIVATE
            src/external_tool.cpp
        PUBLIC
            FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
                FILES
                    ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/external_tool.h
    )
    target_include_directories(external_tool
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
    target_link_libraries(external_tool PUBLIC Boost::filesystem spdlog::spdlog)

    add_executable(ut_external_tool
        test/ut_external_tool.cpp
        src/external_tool.cpp
    )
    target_link_libraries(ut_external_tool PRIVATE GTest::gtest GTest::gmock_main external_tool)
    gtest_discover_tests(ut_external_tool)
endif()

if(Boost_FOUND AND FFMPEG_FOUND)
    add_library(splitter OBJECT)
    add_library(mementor::splitter ALIAS splitter)
    target_sources(splitter
        PRIVATE
            src/demuxer.cpp
            src/source.cpp
            src/extraction.cpp
            src/decoder.cpp
            src/access_unit_adapter.cpp
            src/track_adapter.cpp
        PUBLIC
            FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
            FILES
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/extraction.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/demuxer.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/resample.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/frame_ptr.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/packet_ptr.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/source.h         
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/decoder.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/access_unit_adapter.h
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mementor/track_adapter.h
    )
    target_include_directories(splitter
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
    target_link_libraries(splitter
        PUBLIC
            FFMPEG::avutil
            FFMPEG::avformat
            FFMPEG::avcodec
            FFMPEG::swscale
            FFMPEG::swresample
            spdlog::spdlog
    )

    add_executable(sb_splitter)
    target_sources(sb_splitter
        PRIVATE
            test/sb_splitter.cpp
    )
    target_link_libraries(sb_splitter
        PRIVATE
        Boost::program_options
        Boost::dynamic_linking
        Boost::headers
        splitter
        options
        interruption
        mementor-version-header
    )
endif()

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/mementor-cmake-module-config.cmake.in
[=[
cmake_policy(VERSION 3.18)
@PACKAGE_INIT@

set(MEMENTOR_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "Path to custom CMake modules to use by parent projects")
list(APPEND CMAKE_MODULE_PATH ${MEMENTOR_MODULE_PATH})
]=]
)

configure_package_config_file(
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-cmake-module-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-cmake-module-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/mementor-cmake-module/cmake
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-cmake-module-config.cmake
    DESTINATION  ${CMAKE_INSTALL_DATAROOTDIR}/mementor-cmake-module/cmake
)
install(
    DIRECTORY cmake/
    DESTINATION  ${CMAKE_INSTALL_DATAROOTDIR}/mementor-cmake-module/cmake
)
