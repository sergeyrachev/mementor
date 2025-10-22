cmake_policy(VERSION 3.21)

# This function generates a symbol export header for a given namespace prefix.
# It creates a header file that defines macros for controlling symbol visibility
# in shared and static libraries, depending on the build configuration and platform.
#
# Usage:
#   generate_symbol_export_header(
#       NAMESPACE <namespace>          # The namespace for the generated header. 
#       AS_FOR_SHARED_LIBRARY <Bool>   # A flag to indicate if the library the header belong to is shared library.
#   )
# Example:
#   generate_symbol_export_header(
#       NAMESPACE mylib
#       AS_FOR_SHARED_LIBRARY ${BUILD_SHARED_LIBS}
#   )
#    add_library(mylib)
#   target_sources(mylib  PRIVATE src/mylib.cpp mylib-export-macro PUBLIC mylib-export-header)
#   install(TARGETS mylib mylib-export-header mylib-export-macro ... FILE_SET headers DESTINATION include ... )
#
# Arguments:
#   NAMESPACE: The namespace for the generated header. This is used to create
#              macros specific to the namespace and is used as a prefix for macro names.
#   AS_FOR_SHARED_LIBRARY: A flag to indicate if the library is a shared library. #                          
#
# Outputs:
#   - A header file `export.h` is generated in the build directory
#     under `gen/include/<namespace>/`.
#   - A CMake interface library `<namespace>-export-header` is created, which can
#     be linked to other targets to use the generated header.
#   - A CMake interface library `<namespace>-export-macro` is created, which can
#     be linked to other targets to enable symbol export attribute.
#
# Notes:
#   - The generated header defines macros for symbol visibility based on the
#     platform and whether the library is shared or static.
#   - The function ensures that the export header is only generated once for a
#     given namespace.
function(generate_symbol_export_header)
    set(options "")
    set(single_value_arg NAMESPACE AS_FOR_SHARED_LIBRARY)
    set(multi_value_arg )
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${single_value_arg}" "${multi_value_arg}")

    string(TOUPPER "${arg_NAMESPACE}" NAMESPACE_UPPER)
    string(TOLOWER "${NAMESPACE_UPPER}" NAMESPACE_LOWER)

    if (TARGET ${NAMESPACE_LOWER}-export-header)
        return()
    endif ()

    set(${NAMESPACE_UPPER}_SHARED_LIBRARY ${arg_AS_FOR_SHARED_LIBRARY})
    set(CMAKE_DEFINE "#cmakedefine")
    file(CONFIGURE @ONLY OUTPUT gen/include/${NAMESPACE_LOWER}/export.h.in CONTENT
[=[
#pragma once

@CMAKE_DEFINE@ @NAMESPACE_UPPER@_SHARED_LIBRARY

#if defined(@NAMESPACE_UPPER@_ORIGINAL_BUILD)
    #ifdef @NAMESPACE_UPPER@_SHARED_LIBRARY
        #if defined _WIN32 || defined __CYGWIN__
            #ifdef __GNUC__
                #define @NAMESPACE_UPPER@_PUBLIC __attribute__ ((dllexport))
                #define @NAMESPACE_UPPER@_LOCAL
            #else // MSVC
                #define @NAMESPACE_UPPER@_PUBLIC __declspec(dllexport) // Note: actually gcc seems to also supports this syntax.
                #define @NAMESPACE_UPPER@_LOCAL
            #endif
        #else // *nix SO build
            #if __GNUC__ >= 4
                #define @NAMESPACE_UPPER@_PUBLIC __attribute__ ((visibility ("default")))
                #define @NAMESPACE_UPPER@_LOCAL  __attribute__ ((visibility ("hidden")))
            #else // Unknown compiler
                #define @NAMESPACE_UPPER@_PUBLIC
                #define @NAMESPACE_UPPER@_LOCAL
            #endif
        #endif
    #else // Static library
        #define @NAMESPACE_UPPER@_PUBLIC
        #define @NAMESPACE_UPPER@_LOCAL
    #endif
#else // User-side build
    #ifdef @NAMESPACE_UPPER@_SHARED_LIBRARY
        #if defined _WIN32 || defined __CYGWIN__
            #ifdef __GNUC__
                #define @NAMESPACE_UPPER@_PUBLIC __attribute__ ((dllimport))
                #define @NAMESPACE_UPPER@_LOCAL
            #else // MSVC
                #define @NAMESPACE_UPPER@_PUBLIC __declspec(dllimport) // Note: actually gcc seems to also supports this syntax.
                #define @NAMESPACE_UPPER@_LOCAL
            #endif
        #else
            #if __GNUC__ >= 4
                #define @NAMESPACE_UPPER@_PUBLIC __attribute__ ((visibility ("default")))
                #define @NAMESPACE_UPPER@_LOCAL  __attribute__ ((visibility ("hidden")))
            #else // Unknown compiler
                #define @NAMESPACE_UPPER@_PUBLIC
                #define @NAMESPACE_UPPER@_LOCAL
            #endif
        #endif
    #else // Static library
        #define @NAMESPACE_UPPER@_PUBLIC
        #define @NAMESPACE_UPPER@_LOCAL
    #endif
#endif
]=]
    )
    
    configure_file(${CMAKE_CURRENT_BINARY_DIR}/gen/include/${NAMESPACE_LOWER}/export.h.in ${CMAKE_CURRENT_BINARY_DIR}/gen/include/${NAMESPACE_LOWER}/export.h @ONLY)
    
    add_library(${arg_NAMESPACE}-export-header INTERFACE)
    target_sources(${arg_NAMESPACE}-export-header
        INTERFACE FILE_SET headers TYPE HEADERS BASE_DIRS ${CMAKE_CURRENT_BINARY_DIR}/gen/include FILES ${CMAKE_CURRENT_BINARY_DIR}/gen/include/${NAMESPACE_LOWER}/export.h
    )

    add_library(${arg_NAMESPACE}-export-macro INTERFACE)
    target_compile_definitions(${arg_NAMESPACE}-export-macro INTERFACE ${NAMESPACE_UPPER}_ORIGINAL_BUILD)
endfunction()
