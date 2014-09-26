# /tests/ClangTidy.cmake
# CMake macro to run clang-tidy on target sources.
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)

set (CLANG_TIDY_EXIT_STATUS_WRAPPER_LOCATION
     ${CMAKE_CURRENT_LIST_DIR}/util/ClangTidyExitStatusWrapper.cmake)

function (_validate_clang_tidy CONTINUE)

    find_program (CLANG_TIDY_EXECUTABLE clang-tidy)

    set (${CONTINUE} TRUE PARENT_SCOPE)
    set (CLANG_TIDY_EXECUTABLE ${CLANG_TIDY_EXECUTABLE} PARENT_SCOPE)

endfunction ()

set (CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# TODO: Deduplicate
function (_strip_add_custom_target_sources RETURN_SOURCES TARGET)

    get_target_property (_sources ${TARGET} SOURCES)
    list (GET _sources 0 _first_source)
    string (FIND "${_first_source}" "/" LAST_SLASH REVERSE)
    math (EXPR LAST_SLASH "${LAST_SLASH} + 1")
    string (SUBSTRING "${_first_source}" ${LAST_SLASH} -1 END_OF_SOURCE)

    if (END_OF_SOURCE STREQUAL "${TARGET}")

        list (REMOVE_AT _sources 0)

    endif (END_OF_SOURCE STREQUAL "${TARGET}")

    set (${RETURN_SOURCES} ${_sources} PARENT_SCOPE)

endfunction ()

function (_filter_out_generated_sources RESULT_VARIABLE)

    set (FILTER_OUT_MUTLIVAR_OPTIONS SOURCES)

    cmake_parse_arguments (FILTER_OUT
                           ""
                           ""
                           "${FILTER_OUT_MUTLIVAR_OPTIONS}"
                           ${ARGN})

    set (${RESULT_VARIABLE} PARENT_SCOPE)
    set (FILTERED_SOURCES)

    foreach (SOURCE ${FILTER_OUT_SOURCES})

        get_property (SOURCE_IS_GENERATED
                      SOURCE ${SOURCE}
                      PROPERTY GENERATED)

        if (NOT SOURCE_IS_GENERATED)

            list (APPEND FILTERED_SOURCES ${SOURCE})

        endif (NOT SOURCE_IS_GENERATED)

    endforeach ()

    set (${RESULT_VARIABLE} ${FILTERED_SOURCES} PARENT_SCOPE)

endfunction ()

function (clang_tidy_check_target_sources TARGET)

    set (CHECK_SOURCES_OPTIONS CHECK_GENERATED ALLOW_WARNINGS) 
    set (CHECK_SOURCES_SINGLEVAR_OPTIONS "")
    set (CHECK_SOURCES_MULTIVAR_OPTIONS ENABLE_CHECKS DISABLE_CHECKS)

    cmake_parse_arguments (CHECK_SOURCES
                           "${CHECK_SOURCES_OPTIONS}"
                           "${CHECK_SOURCES_SINGLEVAR_OPTIONS}"
                           "${CHECK_SOURCES_MULTIVAR_OPTIONS}"
                           ${ARGN})

    _strip_add_custom_target_sources (FILES_TO_CHECK ${TARGET})

    if (NOT CHECK_SOURCES_CHECK_GENERATED)
        _filter_out_generated_sources (FILES_TO_CHECK
                                       SOURCES ${FILES_TO_CHECK})
    endif (NOT CHECK_SOURCES_CHECK_GENERATED)

    set (ALLOW_WARNINGS OFF)
    if (CHECK_SOURCES_ALLOW_WARNINGS)
        set (ALLOW_WARNINGS ON)
    endif (CHECK_SOURCES_ALLOW_WARNINGS)


    foreach (SOURCE ${FILES_TO_CHECK})

        get_filename_component (FULL_PATH ${SOURCE} ABSOLUTE)
        add_custom_command (TARGET ${TARGET}
                            PRE_LINK
                            COMMAND
                            ${CMAKE_COMMAND}
                            -DVERBOSE=${CMAKE_VERBOSE_MAKEFILE}
                            -DALLOW_WARNINGS=${ALLOW_WARNINGS}
                            -DCLANG_TIDY_EXECUTABLE=${CLANG_TIDY_EXECUTABLE}
                            -DENABLE_CHECKS=${CHECK_SOURCES_ENABLE_CHECKS}
                            -DDISABLE_CHECKS=${CHECK_SOURCES_DISABLE_CHECKS}
                            -DSOURCE=${SOURCE}
                            -P
                            ${CLANG_TIDY_EXIT_STATUS_WRAPPER_LOCATION})
    endforeach ()

endfunction ()