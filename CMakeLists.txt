cmake_minimum_required(VERSION 3.21)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(GenerateSemanticVersionHeader)
generate_semantic_version_header(NAMESPACE mementor)

project(mementor VERSION ${MEMENTOR_VERSION})
message(STATUS "Build ${PROJECT_NAME}-${MEMENTOR_VERSION_LONG} at ${MEMENTOR_TIMESTAMP} on ${CMAKE_SYSTEM_NAME}")

enable_testing()

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

include(GenerateSymbolExportHeader)
generate_symbol_export_header(NAMESPACE mementor)

find_package(FFMPEG COMPONENTS avcodec avformat swscale swresample)
find_package(Boost 1.70 MODULE REQUIRED COMPONENTS program_options log log_setup)
find_package(CURL)
find_package(spdlog)
find_package(GTest 1.8 CONFIG REQUIRED COMPONENTS gtest gmock gmock_main )

include(GoogleTest)

find_package(PkgConfig)
if (PkgConfig_FOUND)
    pkg_check_modules(UUID libuuid)
endif ()

add_library(singleton OBJECT)
target_sources(singleton
    PRIVATE
        src/singleton.cpp
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/singleton.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/singleton.h>
)

install(
    TARGETS
    singleton
    EXPORT mementor-targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES src/singleton.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

add_library(sighandler INTERFACE)
target_sources(singleton
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/sighandler.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/sighandler.h>
)
install(
    TARGETS
    sighandler
    EXPORT mementor-targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES src/sighandler.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

add_library(hash_fnv1a OBJECT)
target_sources(hash_fnv1a
    PRIVATE
        src/hash_fnv1a.cpp
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/hash_fnv1a.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/hash_fnv1a.h>
)
install(
    TARGETS
        hash_fnv1a
    EXPORT mementor-targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES src/hash_fnv1a.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

add_executable(ut_hash_fnv1a
    test/ut_hash_fnv1a.cpp
    src/hash_fnv1a.cpp
)
target_link_libraries(ut_hash_fnv1a PRIVATE GTest::gtest GTest::gmock_main)
target_include_directories(ut_hash_fnv1a PRIVATE src/)
gtest_discover_tests(ut_hash_fnv1a)

add_library(interruption OBJECT)
target_sources(interruption
    PRIVATE
        src/interruption.cpp
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/interruption.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/interruption.h>
)
install(
    TARGETS
        interruption
    EXPORT mementor-targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES src/interruption.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

add_executable(ut_interruption
    test/ut_interruption.cpp
    src/interruption.cpp
)
target_link_libraries(ut_interruption PRIVATE GTest::gtest GTest::gmock_main)
target_include_directories(ut_interruption PRIVATE src/)
gtest_discover_tests(ut_interruption)

if(UUID_FOUND)
    add_library(uuid INTERFACE)
    target_sources(interruption
        PRIVATE
            src/uuid.cpp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/uuid.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/uuid.h>
    )
    install(
        TARGETS
            uuid
        EXPORT mementor-targets
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
    install(FILES src/uuid.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)
endif()


if(CURL_FOUND)
    add_library(curl OBJECT )
    target_sources(curl
        PRIVATE
            src/curl.cpp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/curl.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/curl.h>
    )
    target_link_libraries(curl PUBLIC CURL::libcurl)
    install(
        TARGETS
            curl
        EXPORT mementor-targets
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
    install(FILES
        src/curl.h
        src/http_error_code.h
        src/response.h
        src/transport_error.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

    add_executable(ut_curl
        test/ut_curl.cpp
        src/curl.cpp
        )
    target_link_libraries(ut_curl PRIVATE GTest::gmock GTest::gmock_main CURL::libcurl)
    target_include_directories(ut_curl PRIVATE src/)
    gtest_discover_tests(ut_curl)
endif()

if(Boost_FOUND)
    add_library(ntp OBJECT src/ntp.cpp)
    target_sources(ntp
        PRIVATE
            src/ntp.cpp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/ntp.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/ntp.h>
    )
    target_link_libraries(ntp PUBLIC Boost::date_time)
    install(
        TARGETS
            ntp
        EXPORT mementor-targets
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
    install(FILES src/ntp.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

    add_executable(ut_ntp
        test/ut_ntp.cpp
        src/ntp.cpp
    )
    target_link_libraries(ut_ntp PRIVATE GTest::gtest GTest::gmock_main Boost::date_time)
    target_include_directories(ut_ntp PRIVATE src/)
    gtest_discover_tests(ut_ntp)

    add_library(options OBJECT)
    target_sources(options
        PRIVATE
            src/options.cpp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/options.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/options.h>
    )
    target_link_libraries(options PUBLIC Boost::program_options )
    install(
        TARGETS
        options
        EXPORT mementor-targets
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
    install(FILES src/options.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

    add_executable(ut_options
        test/ut_options.cpp
        src/options.cpp
    )
    target_link_libraries(ut_options PRIVATE GTest::gtest GTest::gmock_main Boost::program_options)
    target_include_directories(ut_options PRIVATE src/)
    gtest_discover_tests(ut_options)
endif()

if(NOT ${CMAKE_HOST_WIN32} AND Boost_FOUND AND spdlog_FOUND)
    add_library(external_tool OBJECT)
    target_sources(external_tool
        PRIVATE
            src/external_tool.cpp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/external_tool.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/external_tool.h>
    )
    target_link_libraries(external_tool PUBLIC Boost::filesystem spdlog::spdlog)
    install(
        TARGETS
            external_tool
        EXPORT mementor-targets
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
    install(FILES src/external_tool.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)
    
    add_executable(ut_external_tool
        test/ut_external_tool.cpp
        src/external_tool.cpp
    )
    target_link_libraries(ut_external_tool PRIVATE GTest::gtest GTest::gmock_main Boost::filesystem spdlog::spdlog)
    target_include_directories(ut_external_tool PRIVATE src/)
    gtest_discover_tests(ut_external_tool)
endif()

if(Boost_FOUND AND FFMPEG_FOUND)
    add_library(splitter OBJECT)
    target_sources(splitter
        PRIVATE
            src/demuxer.cpp
            src/source.cpp
            src/extraction.cpp
            src/decoder.cpp
            src/interruption.cpp
            src/options.cpp
            src/access_unit_adapter.cpp
            src/track_adapter.cpp
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/extraction.h> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mementor/extraction.h>
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
    install(
        TARGETS
            splitter
        EXPORT mementor-targets
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        OBJECTS DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )
    install(FILES src/extraction.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mementor)

    add_executable(sb_splitter)
    target_sources(sb_splitter
        PRIVATE
            test/sb_splitter.cpp
    )
    target_include_directories(sb_splitter PRIVATE src)
    target_link_libraries(sb_splitter
        PRIVATE
        Boost::program_options
        Boost::dynamic_linking
        Boost::headers
        mementor::splitter
        mementor-version-header
    )
endif()


file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/mementor-config.cmake.in
[=[
cmake_policy(VERSION 3.18)
@PACKAGE_INIT@
include ( "${CMAKE_CURRENT_LIST_DIR}/mementor-targets.cmake" )

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_LIST_DIR}/modules")
]=]
)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-config-version.cmake
    VERSION ${MEMENTOR_VERSION}
    COMPATIBILITY AnyNewerVersion
)
configure_package_config_file(
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}
)

install(EXPORT mementor-targets
    FILE mementor-targets.cmake
    NAMESPACE mementor::
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/mementor/cmake
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/mementor-config-version.cmake
    DESTINATION  ${CMAKE_INSTALL_DATAROOTDIR}/mementor/cmake
)

install(DIRECTORY
    cmake/
    DESTINATION  ${CMAKE_INSTALL_DATAROOTDIR}/mementor/cmake/modules
)
