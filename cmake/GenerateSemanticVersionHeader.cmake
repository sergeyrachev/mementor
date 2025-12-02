cmake_policy(VERSION 3.21)

function(set_semantic_version_variables)
    set(options "")
    set(single_value_arg NAMESPACE )
    set(multi_value_arg )
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${single_value_arg}" "${multi_value_arg}")

    string(TOUPPER "${arg_NAMESPACE}" NAMESPACE_UPPER)
    string(TOLOWER "${NAMESPACE_UPPER}" NAMESPACE_LOWER)

    set(SEMVER_MAJOR_DEFAULT 0)
    set(SEMVER_MINOR_DEFAULT 0)
    set(SEMVER_PATCH_DEFAULT 0)
    set(SEMVER_TWEAK_DEFAULT 0)
    set(SEMVER_BUILD_DEFAULT 0)
    set(SEMVER_REVISION_DEFAULT "00000000")
    set(SEMVER_PHASE_DEFAULT "dev")
    set(SEMVER_CI_DEFAULT "local")
    string(TIMESTAMP SEMVER_TIMESTAMP_DEFAULT "%Y%m%dT%H%M%SZ" UTC)
    string(TIMESTAMP SEMVER_TIMESTAMP_RFC UTC)

    if (NOT DEFINED ENV{SEMVER_MAJOR})
        set(ENV{SEMVER_MAJOR} ${SEMVER_MAJOR_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_MINOR})
        set(ENV{SEMVER_MINOR} ${SEMVER_MINOR_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_PATCH})
        set(ENV{SEMVER_PATCH} ${SEMVER_PATCH_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_TWEAK})
        set(ENV{SEMVER_TWEAK} ${SEMVER_TWEAK_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_BUILD})
        set(ENV{SEMVER_BUILD} ${SEMVER_BUILD_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_REVISION})
        set(ENV{SEMVER_REVISION} ${SEMVER_REVISION_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_PHASE})
        set(ENV{SEMVER_PHASE} ${SEMVER_PHASE_DEFAULT})
    endif ()
    if (NOT DEFINED ENV{SEMVER_TIMESTAMP})
        set(ENV{SEMVER_TIMESTAMP} ${SEMVER_TIMESTAMP_DEFAULT})
    endif ()

    set(SEMVER_CI_PREFIXED ".$ENV{SEMVER_CI}")
    if (NOT DEFINED ENV{SEMVER_CI})
        set(SEMVER_CI_PREFIXED ".${SEMVER_CI_DEFAULT}")
    endif ()

    set(SEMVER_MNEMONIC_PREFIXED ".$ENV{SEMVER_MNEMONIC}")
    if (NOT DEFINED ENV{SEMVER_MNEMONIC})
        set(SEMVER_MNEMONIC_PREFIXED "")
    endif ()

    set(SEMVER_DIRTY_PREFIXED ".$ENV{SEMVER_DIRTY}")
    if (NOT DEFINED ENV{SEMVER_DIRTY})
        set(SEMVER_DIRTY_PREFIXED "")
    endif ()

    set(SEMVER_VERSIONCORE "$ENV{SEMVER_MAJOR}.$ENV{SEMVER_MINOR}.$ENV{SEMVER_PATCH}.$ENV{SEMVER_TWEAK}")
    set(SEMVER_PRERELEASE "$ENV{SEMVER_PHASE}")
    set(SEMVER_BUILDINFO "$ENV{SEMVER_REVISION}.b$ENV{SEMVER_BUILD}.$ENV{SEMVER_TIMESTAMP}${SEMVER_MNEMONIC_PREFIXED}${SEMVER_DIRTY_PREFIXED}${SEMVER_CI_PREFIXED}")
    set(SEMVER_VERSION "${SEMVER_VERSIONCORE}-${SEMVER_PRERELEASE}+${SEMVER_BUILDINFO}")

    set(${NAMESPACE_UPPER}_VERSION_LONG ${SEMVER_VERSION} CACHE INTERNAL "Full Version String")
    set(${NAMESPACE_UPPER}_VERSION ${SEMVER_VERSIONCORE} CACHE INTERNAL "Version String")
    set(${NAMESPACE_UPPER}_TIMESTAMP ${SEMVER_TIMESTAMP_RFC} CACHE INTERNAL "Version Timestamp RFC")

    set(${NAMESPACE_UPPER}_SEMVER_MAJOR $ENV{SEMVER_MAJOR} CACHE INTERNAL "Version Major")
    set(${NAMESPACE_UPPER}_SEMVER_MINOR $ENV{SEMVER_MINOR} CACHE INTERNAL "Version Minor")
    set(${NAMESPACE_UPPER}_SEMVER_PATCH $ENV{SEMVER_PATCH} CACHE INTERNAL "Version Patch")
    set(${NAMESPACE_UPPER}_SEMVER_TWEAK $ENV{SEMVER_TWEAK} CACHE INTERNAL "Version Tweak")
    set(${NAMESPACE_UPPER}_SEMVER_BUILD $ENV{SEMVER_BUILD} CACHE INTERNAL "Version Build")
    set(${NAMESPACE_UPPER}_SEMVER_REVISION $ENV{SEMVER_REVISION} CACHE INTERNAL "Version Revision")
    set(${NAMESPACE_UPPER}_SEMVER_PHASE $ENV{SEMVER_PHASE} CACHE INTERNAL "Version Phase")
    set(${NAMESPACE_UPPER}_SEMVER_CI $ENV{SEMVER_CI} CACHE INTERNAL "Version CI")
    set(${NAMESPACE_UPPER}_SEMVER_TIMESTAMP $ENV{SEMVER_TIMESTAMP} CACHE INTERNAL "Version Timestamp Short")
endfunction()

function(generate_semantic_version_header)
    set(options "")
    set(single_value_arg NAMESPACE )
    set(multi_value_arg )
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${single_value_arg}" "${multi_value_arg}")

    string(TOUPPER "${arg_NAMESPACE}" NAMESPACE_UPPER)
    string(TOLOWER "${NAMESPACE_UPPER}" NAMESPACE_LOWER)

    if (TARGET ${NAMESPACE_LOWER}-version-header)
        return()
    endif ()

    file(CONFIGURE @ONLY OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/gen/src/${NAMESPACE_LOWER}/version.h CONTENT
[=[
#pragma once

#include <string>

namespace @NAMESPACE_LOWER@ {
    extern const std::string version;
    extern const std::string birthday;
}
]=])

    file(CONFIGURE @ONLY OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/gen/src/${NAMESPACE_LOWER}/version.cpp CONTENT
[=[
#include "@NAMESPACE_LOWER@/version.h"
namespace @NAMESPACE_LOWER@ {
    const std::string version = "@SEMVER_VERSION@";
    const std::string birthday = "@SEMVER_TIMESTAMP_RFC@";
}
]=]
    )
    
    add_library(${NAMESPACE_LOWER}-version-header OBJECT)
    target_sources(${NAMESPACE_LOWER}-version-header
        PRIVATE
            ${CMAKE_CURRENT_BINARY_DIR}/gen/src/${NAMESPACE_LOWER}/version.cpp
            ${CMAKE_CURRENT_BINARY_DIR}/gen/src/${NAMESPACE_LOWER}/version.h
    )
    target_include_directories(${NAMESPACE_LOWER}-version-header PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/gen/src/>)
endfunction()
