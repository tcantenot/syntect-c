# FindSyntectC.cmake
# Locates the correct pre-built syntect-c static library and exposes it
# as the imported target SyntectC::SyntectC.
#
# Usage:
#   list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/third_party/syntect-c/cmake")
#   find_package(SyntectC REQUIRED)
#   target_link_libraries(my_target PRIVATE SyntectC::SyntectC)

cmake_minimum_required(VERSION 3.19)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
        set(_SC_PLAT "linux-aarch64")
    else()
        set(_SC_PLAT "linux-x86_64")
    endif()
    set(_SC_LIB "libsyntect_c.a")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(_SC_PLAT "macos-universal")
    set(_SC_LIB "libsyntect_c.a")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(_SC_PLAT "windows-x86_64")
    set(_SC_LIB "syntect_c.lib")
else()
    message(FATAL_ERROR "FindSyntectC: unsupported platform '${CMAKE_SYSTEM_NAME}'.")
endif()

set(_SC_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
set(_SC_LIB_PATH "${_SC_ROOT}/lib/${_SC_PLAT}/${_SC_LIB}")
set(_SC_INC_PATH "${_SC_ROOT}/include")

if(NOT EXISTS "${_SC_LIB_PATH}")
    if(SyntectC_FIND_REQUIRED)
        message(FATAL_ERROR
            "FindSyntectC: pre-built library not found:\n"
            "  ${_SC_LIB_PATH}\n"
            "Run scripts/build-syntect.sh (or .ps1 on Windows).")
    else()
        set(SyntectC_FOUND FALSE)
        return()
    endif()
endif()

if(NOT TARGET SyntectC::SyntectC)
    add_library(SyntectC::SyntectC STATIC IMPORTED)
    set_target_properties(SyntectC::SyntectC PROPERTIES
        IMPORTED_LOCATION             "${_SC_LIB_PATH}"
        INTERFACE_INCLUDE_DIRECTORIES "${_SC_INC_PATH}"
    )
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set_property(TARGET SyntectC::SyntectC APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES ws2_32 userenv bcrypt ntdll)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        set_property(TARGET SyntectC::SyntectC APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES "-framework Security" "-framework CoreFoundation")
    else()
        set_property(TARGET SyntectC::SyntectC APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES pthread dl m)
    endif()
endif()

set(SyntectC_FOUND TRUE)
set(SyntectC_INCLUDE_DIRS "${_SC_INC_PATH}")
set(SyntectC_LIBRARIES    SyntectC::SyntectC)

if(NOT SyntectC_FIND_QUIETLY)
    message(STATUS "Found SyntectC: ${_SC_LIB_PATH}")
endif()
