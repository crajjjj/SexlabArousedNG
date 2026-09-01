cmake_minimum_required(VERSION 3.21)
message("Using toolchain file ${CMAKE_TOOLCHAIN_FILE}.")

########################################################################################################################
## Define project
########################################################################################################################
project(
        SexlabArousedNG
        VERSION 3.3.5
        DESCRIPTION "Next generation arousal for Sexlab and Ostim"
        LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)

include(GNUInstallDirs)

configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/version.rc
        @ONLY)

set(headers
        include/Papyrus.h
        include/ArousalManager.h
        include/ArousalData.h
        include/ArousalAPI.h
        include/CosSin.h
        include/SerializationHelper.h
    )

set(sources
        src/Main.cpp
        src/Papyrus.cpp
        src/ArousalManager.cpp
        src/ArousalData.cpp
        src/ArousalAPI.cpp
        src/SerializationHelper.cpp

        ${CMAKE_CURRENT_BINARY_DIR}/version.rc)

set(tests
        test/ArousalMath.cpp
    )

source_group(
        TREE ${CMAKE_CURRENT_SOURCE_DIR}
        FILES
        ${headers}
        ${sources}
        ${tests})

#########################################################################################################################
### Build options
#########################################################################################################################
message("Options:")
option(BUILD_TESTS "Build unit tests." OFF)
message("\tTests: ${BUILD_TESTS}")

########################################################################################################################
## Configure target DLL
########################################################################################################################
# CommonLibSSE-NG (alandtse fork, https://github.com/alandtse/CommonLibSSE-NG) is
# vendored as a git submodule pinned to v7.0.0 -- required for Skyrim 1.7.99, which
# shipped Address Library format 5 (the plugin declaration's AddressLibraryV5 flag is
# set automatically when building against NG >= 6.7.0). Its build dependencies
# (spdlog, rapidcsv, directxtk) come from vcpkg -- see vcpkg.json.
# Run `git submodule update --init --recursive` once before configuring.
set(SKSE_SUPPORT_PATCH_SAFETY OFF) # trampoline patch validation; this plugin writes no
                                   # hooks, and OFF avoids a configure-time FetchContent
                                   # download of minhook's hde64.
set(_sla_build_tests "${BUILD_TESTS}")
set(BUILD_TESTS OFF) # never build CommonLibSSE-NG's own unit tests (would require Catch2)
add_subdirectory(lib/commonlibsse-ng EXCLUDE_FROM_ALL)
set(BUILD_TESTS "${_sla_build_tests}")
unset(_sla_build_tests)

# The source (non-prebuilt) build of CommonLibSSE-NG does not include its consumer
# helper module itself (only the find_package config and prebuilt paths do) -- pull
# in add_commonlibsse_plugin() explicitly.
if(NOT COMMAND add_commonlibsse_plugin)
    include(lib/commonlibsse-ng/cmake/CommonLibSSE.cmake)
endif()

add_commonlibsse_plugin(${PROJECT_NAME} SOURCES ${headers} ${sources})
add_library("${PROJECT_NAME}::${PROJECT_NAME}" ALIAS "${PROJECT_NAME}")

target_include_directories(${PROJECT_NAME}
        PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/src>
        $<INSTALL_INTERFACE:src>)

target_include_directories(${PROJECT_NAME}
        PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

# Turns the SLA_* declarations in include/ArousalAPI.h into real exports. The header
# defaults to NO storage class so consumers can copy and include it without their own
# plugin re-exporting (or link-depending on) our symbols -- only this build exports.
target_compile_definitions(${PROJECT_NAME}
        PRIVATE
        SLA_BUILDING_DLL)

target_precompile_headers(${PROJECT_NAME}
        PRIVATE
        src/PCH.h)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

install(TARGETS ${PROJECT_NAME}
        DESTINATION "${CMAKE_INSTALL_LIBDIR}")

########################################################################################################################
## Automatic plugin deployment: ONLY DLL to dist/Core/SKSE/Plugins
########################################################################################################################
set(PLUGIN_DIST_DIR "${CMAKE_SOURCE_DIR}/dist/Core/SKSE/Plugins")

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PLUGIN_DIST_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:${PROJECT_NAME}>"
        "${PLUGIN_DIST_DIR}/"
    COMMENT "Deploying ONLY DLL to /dist/Core/SKSE/Plugins"
)

# (Optional) Clean just DLLs from dist/Core/SKSE/Plugins when cleaning target
file(GLOB OUTPUT_DLLS "${PLUGIN_DIST_DIR}/*.dll")
set_property(TARGET ${PROJECT_NAME}
        APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${OUTPUT_DLLS}")
