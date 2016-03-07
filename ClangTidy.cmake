# /ClangTidy.cmake
#
# CMake macro to run clang-tidy on target sources.
#
# See /LICENCE.md for Copyright information

include (CMakeParseArguments)
include ("cmake/tooling-cmake-util/PolysquareToolingUtil")

set (CLANG_TIDY_EXIT_STATUS_WRAPPER_LOCATION
     "${CMAKE_CURRENT_LIST_DIR}/util/ClangTidyExitStatusWrapper.cmake")

macro (clang_tidy_validate CONTINUE)

    if (NOT DEFINED CLANG_TIDY_FOUND)

        find_package (CLANGTIDY ${ARGN})

    endif ()

    set (${CONTINUE} ${CLANG_TIDY_FOUND})

endmacro ()

set (CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

function (clang_tidy_check_target_sources TARGET)

    set (CHECK_SOURCES_OPTIONS
         CHECK_GENERATED
         WARN_ONLY)
    set (CHECK_SOURCES_SINGLEVAR_OPTIONS
         FORCE_LANGUAGE)
    set (CHECK_SOURCES_MULTIVAR_OPTIONS
         ENABLE_CHECKS
         DISABLE_CHECKS
         INTERNAL_INCLUDE_DIRS
         EXTERNAL_INCLUDE_DIRS
         DEFINES
         CPP_IDENTIFIERS
         DEPENDS)

    cmake_parse_arguments (CHECK_SOURCES
                           "${CHECK_SOURCES_OPTIONS}"
                           "${CHECK_SOURCES_SINGLEVAR_OPTIONS}"
                           "${CHECK_SOURCES_MULTIVAR_OPTIONS}"
                           ${ARGN})

    psq_strip_extraneous_sources (FILES_TO_CHECK ${TARGET})
    psq_handle_check_generated_option (CHECK_SOURCES FILES_TO_CHECK
                                       SOURCES ${FILES_TO_CHECK})

    string (REPLACE ";" "," ENABLE_CHECKS_LIST "${CHECK_SOURCES_ENABLE_CHECKS}")
    string (REPLACE ";" "," DISABLE_CHECKS_LIST
            "${CHECK_SOURCES_DISABLE_CHECKS}")

    set (CLANG_TIDY_OPTIONS
         -DVERBOSE=${CMAKE_VERBOSE_MAKEFILE}
         "-DCLANG_TIDY_EXECUTABLE=${CLANG_TIDY_EXECUTABLE}"
         -DENABLE_CHECKS=${ENABLE_CHECKS_LIST}
         -DDISABLE_CHECKS=${DISABLE_CHECKS_LIST})

    psq_add_switch (CLANG_TIDY_OPTIONS CHECK_SOURCES_WARN_ONLY
                    ON -DWARN_ONLY=ON
                    OFF -DWARN_ONLY=OFF)

    # Scan each source file to determine its language. We might need
    # it later when generating a compilation database.
    if (CHECK_SOURCES_FORCE_LANGUAGE)

        set (FORCE_LANGUAGE_OPTION
             FORCE_LANGUAGE ${CHECK_SOURCES_FORCE_LANGUAGE})

    endif ()

    # Scan source languages and sort them out now. We will pass
    # each of these lists to psq_make_compilation_db for later
    # use.
    psq_forward_options (CHECK_SOURCES SORT_TO_LANGS_FORWARD_OPTIONS
                         SINGLEVAR_ARGS FORCE_LANGUAGE
                         MULTIVAR_ARGS CPP_IDENTIFIERS)
    psq_sort_sources_to_languages (C_SOURCES CXX_SOURCES HEADERS
                                   SOURCES ${FILES_TO_CHECK}
                                   ${SORT_TO_LANGS_FORWARD_OPTIONS}
                                   INCLUDES
                                   ${CHECK_SOURCES_INTERNAL_INCLUDE_DIRS})

    # By default, fall back to using generated compilation database
    # until it can be proven that using the CMake generated one is a better
    # choice.
    set (CUSTOM_COMPILATION_DB_SOURCES ${FILES_TO_CHECK})

    if (CMAKE_GENERATOR STREQUAL "Ninja" OR
        CMAKE_GENERATOR STREQUAL "Unix Makefiles")

        psq_get_target_command_attach_point (${TARGET} WHEN)

        # A compilation database is generated for all linkable targets, so
        # if we're running PRE_LINK then use that
        if (WHEN STREQUAL "PRE_LINK")

            set (CUSTOM_COMPILATION_DB_SOURCES ${HEADERS})

        endif ()

    endif (CMAKE_GENERATOR STREQUAL "Ninja" OR
           CMAKE_GENERATOR STREQUAL "Unix Makefiles")

    # Keep C_SOURCES and CXX_SOURCES intersecting with the sources
    # we wish to make a compilation DB for.
    psq_get_list_intersection (C_COMP_DB_SOURCES
                               SOURCE ${C_SOURCES}
                               INTERSECTION ${CUSTOM_COMPILATION_DB_SOURCES})
    psq_get_list_intersection (CXX_COMP_DB_SOURCES
                               SOURCE ${CXX_SOURCES}
                               INTERSECTION ${CUSTOM_COMPILATION_DB_SOURCES})

    # For mixed source-header targets or UTILITY targets, we need
    # to generate a fake compilation database as CMake won't do it
    # for us in this instance.
    psq_make_compilation_db (${TARGET}
                             CUSTOM_COMPILATION_DB_DIR
                             ${FORCE_LANGUAGE_OPTION}
                             C_SOURCES ${C_COMP_DB_SOURCES}
                             CXX_SOURCES ${CXX_COMP_DB_SOURCES}
                             INTERNAL_INCLUDE_DIRS
                             ${CHECK_SOURCES_INTERNAL_INCLUDE_DIRS}
                             EXTERNAL_INCLUDE_DIRS
                             ${CHECK_SOURCES_EXTERNAL_INCLUDE_DIRS}
                             DEFINES
                             ${CHECK_SOURCES_DEFINES})

    foreach (SOURCE ${FILES_TO_CHECK})

        # Check if this source is one that requires a custom
        # compilation database
        list (FIND CUSTOM_COMPILATION_DB_SOURCES "${SOURCE}" SOURCE_INDEX)

        if (NOT SOURCE_INDEX EQUAL -1)

            set (SOURCE_COMP_DB "${CUSTOM_COMPILATION_DB_DIR}")

        else ()

            set (SOURCE_COMP_DB "${CMAKE_BINARY_DIR}")

        endif ()

        psq_forward_options (CHECK_SOURCES RUN_TOOL_ON_SOURCE_FORWARD
                             MULTIVAR_ARGS DEPENDS)
        psq_run_tool_on_source (${TARGET} "${SOURCE}" "clang-tidy"
                                COMMAND
                                "${CMAKE_COMMAND}"
                                "-DSOURCE=${SOURCE}"
                                -DCUSTOM_COMPILATION_DB_DIR=${SOURCE_COMP_DB}
                                ${CLANG_TIDY_OPTIONS}
                                -P
                                ${CLANG_TIDY_EXIT_STATUS_WRAPPER_LOCATION}
                                ${RUN_TOOL_ON_SOURCE_FORWARD})
    endforeach ()

endfunction ()
