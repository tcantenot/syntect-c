cmake_minimum_required(VERSION 3.19)
project(syntect_demo C)
set(CMAKE_C_STANDARD 11)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../cmake")
find_package(SyntectC REQUIRED)

add_executable(demo demo.c)
target_link_libraries(demo PRIVATE SyntectC::SyntectC)
