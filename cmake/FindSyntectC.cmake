# FindSyntectC.cmake
# Locates the correct pre-built syntect-c library and exposes it as the
# imported target SyntectC::SyntectC.
#
# Options (set before find_package):
#   SYNTECT_C_SHARED  — if TRUE, link the shared library instead of the static one.
#                       Default: FALSE.
#
# Usage (static — existing consumers unchanged):
#   list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/third_party/syntect-c/cmake")
#   find_package(SyntectC REQUIRED)
#   target_link_libraries(my_target PRIVATE SyntectC::SyntectC)
#
# Usage (shared):
#   set(SYNTECT_C_SHARED TRUE)
#   find_package(SyntectC REQUIRED)
#   target_link_libraries(my_target PRIVATE SyntectC::SyntectC)
#   # On Windows, copy syntect_c.dll next to your executable at install/run time.
#
# Note: if find_package(SyntectC) is called more than once in the same CMake
# session, the first call wins — SYNTECT_C_SHARED cannot be changed mid-session.

cmake_minimum_required(VERSION 3.19)

option(SYNTECT_C_SHARED "Link syntect-c as a shared library" OFF)

# --- Platform detection ---
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
        set(_SC_PLAT "linux-aarch64")
    else()
        set(_SC_PLAT "linux-x86_64")
    endif()
    set(_SC_STATIC "libsyntect_c.a")
    set(_SC_SHARED "libsyntect_c.so")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(_SC_PLAT   "macos-universal")
    set(_SC_STATIC "libsyntect_c.a")
    set(_SC_SHARED "libsyntect_c.dylib")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(_SC_PLAT   "windows-x86_64")
    set(_SC_STATIC "syntect_c.lib")
    set(_SC_SHARED "syntect_c.dll")
    set(_SC_IMPLIB "syntect_c.dll.lib")
else()
    message(FATAL_ERROR "FindSyntectC: unsupported platform '${CMAKE_SYSTEM_NAME}'.")
endif()

set(_SC_ROOT     "${CMAKE_CURRENT_LIST_DIR}/..")
set(_SC_INC_PATH "${_SC_ROOT}/include")

# --- Select library file(s) ---
if(SYNTECT_C_SHARED)
    set(_SC_LIB_PATH "${_SC_ROOT}/lib/${_SC_PLAT}/${_SC_SHARED}")
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_SC_IMP_PATH "${_SC_ROOT}/lib/${_SC_PLAT}/${_SC_IMPLIB}")
    endif()
else()
    set(_SC_LIB_PATH "${_SC_ROOT}/lib/${_SC_PLAT}/${_SC_STATIC}")
endif()

# --- Existence check ---
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

if(SYNTECT_C_SHARED AND CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if(NOT EXISTS "${_SC_IMP_PATH}")
        if(SyntectC_FIND_REQUIRED)
            message(FATAL_ERROR
                "FindSyntectC: DLL import library not found:\n"
                "  ${_SC_IMP_PATH}\n"
                "Run scripts/build-syntect.ps1.")
        else()
            set(SyntectC_FOUND FALSE)
            return()
        endif()
    endif()
endif()

# --- Create imported target ---
if(NOT TARGET SyntectC::SyntectC)
    if(SYNTECT_C_SHARED)
        add_library(SyntectC::SyntectC SHARED IMPORTED)
        set_target_properties(SyntectC::SyntectC PROPERTIES
            IMPORTED_LOCATION             "${_SC_LIB_PATH}"
            INTERFACE_INCLUDE_DIRECTORIES "${_SC_INC_PATH}"
            INTERFACE_COMPILE_DEFINITIONS "SYNTECT_C_SHARED"
        )
        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            set_target_properties(SyntectC::SyntectC PROPERTIES
                IMPORTED_IMPLIB "${_SC_IMP_PATH}"
            )
        endif()
        # Shared libraries carry their own transitive dependencies; no
        # INTERFACE_LINK_LIBRARIES needed on the consumer side.
    else()
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
endif()

set(SyntectC_FOUND TRUE)
set(SyntectC_INCLUDE_DIRS "${_SC_INC_PATH}")
set(SyntectC_LIBRARIES    SyntectC::SyntectC)

if(NOT SyntectC_FIND_QUIETLY)
    if(SYNTECT_C_SHARED)
        message(STATUS "Found SyntectC (shared): ${_SC_LIB_PATH}")
    else()
        message(STATUS "Found SyntectC (static): ${_SC_LIB_PATH}")
    endif()
endif()
