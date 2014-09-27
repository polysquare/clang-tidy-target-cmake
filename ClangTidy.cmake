# /tests/ClangTidy.cmake
# CMake macro to run clang-tidy on target sources.
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)
include (${CMAKE_CURRENT_LIST_DIR}/determine-header-language/DetermineHeaderLanguage.cmake)

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

function (_psq_make_compilation_db TARGET
                                   COMPILATION_DB_DIR_RETURN)

    set (MAKE_COMP_DB_OPTIONS)
    set (MAKE_COMP_DB_SINGLEVAR_OPTIONS
         FORCE_LANGUAGE)
    set (MAKE_COMP_DB_MULTIVAR_OPTIONS
         SOURCES
         INTERNAL_INCLUDE_DIRS
         EXTERNAL_INCLUDE_DIRS
         DEFINES)

    cmake_parse_arguments (MAKE_COMP_DB
                           "${MAKE_COMP_DB_OPTIONS}"
                           "${MAKE_COMP_DB_SINGLEVAR_OPTIONS}"
                           "${MAKE_COMP_DB_MULTIVAR_OPTIONS}"
                           ${ARGN})

    set (COMPILATION_DB_DIR
         ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_compile_commands/)
    set (COMPILATION_DB_FILE
         ${COMPILATION_DB_DIR}/compile_commands.json)

    set (COMPILATION_DB_FILE_CONTENTS
         "[")

    foreach (SOURCE ${MAKE_COMP_DB_SOURCES})

        get_filename_component (FULL_PATH ${SOURCE} ABSOLUTE)
        get_filename_component (BASENAME ${SOURCE} NAME)

        set (LANGUAGE ${MAKE_COMP_DB_FORCE_LANGUAGE})
        if (NOT LANGUAGE)

            # Get the language of the file.
            polysquare_determine_language_for_source (${FULL_PATH}
                                                      LANGUAGE
                                                      SOURCE_WAS_HEADER
                                                      INCLUDES
                                                      ${ALL_INCLUDE_DIRS})

        endif (NOT LANGUAGE)

        set (COMPILATION_DB_FILE_CONTENTS
             "${COMPILATION_DB_FILE_CONTENTS}\n{\n"
             "\"directory\": \"${CMAKE_CURRENT_BINARY_DIR}\",\n"
             "\"command\": \"${CMAKE_CXX_COMPILER}"
             " -o CMakeFiles/${TARGET}.dir/${BASENAME}.o"
             " -c ${FULL_PATH}")

        # All includes
        foreach (INTERNAL_INCLUDE ${MAKE_COMP_DB_INTERNAL_INCLUDE_DIRS})

            set (COMPILATION_DB_FILE_CONTENTS
                 "${COMPILATION_DB_FILE_CONTENTS} -I${INTERNAL_INCLUDE}")

        endforeach ()

        foreach (EXTERNAL_INCLUDE ${MAKE_COMP_DB_EXTERNAL_INCLUDE_DIRS})

            set (COMPILATION_DB_FILE_CONTENTS
                 "${COMPILATION_DB_FILE_CONTENTS}"
                 "-isystem${EXTERNAL_INCLUDE}")

        endforeach ()

        # All defines
        foreach (DEFINE ${MAKE_COMP_DB_DEFINES})

            set (COMPILATION_DB_FILE_CONTENTS
                 "${COMPILATION_DB_FILE_CONTENTS} -D${DEFINE}")

        endforeach ()

        # CXXFLAGS / CFLAGS
        list (FIND LANGUAGE "CXX" CXX_INDEX)

        if (NOT CXX_INDEX EQUAL -1)

            # Only redefine __cplusplus if this is a header file
            if (SOURCE_WAS_HEADER)

                set (COMPILATION_DB_FILE_CONTENTS
                     "${COMPILATION_DB_FILE_CONTENTS} -D__cplusplus")

            endif (SOURCE_WAS_HEADER)

            # Add CMAKE_CXX_FLAGS
            set (COMPILATION_DB_FILE_CONTENTS
                 "${COMPILATION_DB_FILE_CONTENTS} ${CMAKE_CXX_FLAGS}")

        else (NOT CXX_INDEX EQUAL -1)

            set (COMPILATION_DB_FILE_CONTENTS
                 "${COMPILATION_DB_FILE_CONTENTS} ${CMAKE_C_FLAGS}")

        endif (NOT CXX_INDEX EQUAL -1)

        set (COMPILATION_DB_FILE_CONTENTS
             "${COMPILATION_DB_FILE_CONTENTS}\",\n"
             "\"file\": \"${FULL_PATH}\"\n"
             "},")

    endforeach ()

    # Get rid of all the semicolons
    string (REPLACE ";" ""
            COMPILATION_DB_FILE_CONTENTS
            "${COMPILATION_DB_FILE_CONTENTS}")

    # Take away the last comma
    string (LENGTH
            "${COMPILATION_DB_FILE_CONTENTS}"
            COMPILATION_DB_FILE_LENGTH)
    math (EXPR TRIMMED_COMPILATION_DB_FILE_LENGTH
          "${COMPILATION_DB_FILE_LENGTH} - 1")
    string (SUBSTRING "${COMPILATION_DB_FILE_CONTENTS}"
            0 ${TRIMMED_COMPILATION_DB_FILE_LENGTH}
            COMPILATION_DB_FILE_CONTENTS)

    # Final "]"
    set (COMPILATION_DB_FILE_CONTENTS
         "${COMPILATION_DB_FILE_CONTENTS}\n]\n")

    # Write out
    file (WRITE ${COMPILATION_DB_FILE}
          ${COMPILATION_DB_FILE_CONTENTS})

    set (${COMPILATION_DB_DIR_RETURN}
         ${COMPILATION_DB_DIR} PARENT_SCOPE)

endfunction (_psq_make_compilation_db)

function (clang_tidy_check_target_sources TARGET)

    set (CHECK_SOURCES_OPTIONS
         CHECK_GENERATED
         ALLOW_WARNINGS)
    set (CHECK_SOURCES_SINGLEVAR_OPTIONS
         FORCE_LANGUAGE)
    set (CHECK_SOURCES_MULTIVAR_OPTIONS
         ENABLE_CHECKS
         DISABLE_CHECKS
         INTERNAL_INCLUDE_DIRS
         EXTERNAL_INCLUDE_DIRS
         DEFINES
         CPP_IDENTIFIERS)

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

    # Figure out if this target is linkable. If it is a UTILITY
    # target then we need to run the checks at the PRE_BUILD stage.
    set (WHEN PRE_LINK)

    get_property (TARGET_TYPE
                  TARGET ${TARGET}
                  PROPERTY TYPE)

    # Scan each source file to determine its language. We might need
    # it later when generating a compilation database.
    set (ALL_INCLUDE_DIRS
         ${CHECK_SOURCES_INTERNAL_INCLUDE_DIRS}
         ${CHECK_SOURCES_EXTERNAL_INCLUDE_DIRS})

    foreach (SOURCE ${FILES_TO_CHECK})

        polysquare_scan_source_for_headers (SOURCE ${SOURCE}
                                            INCLUDES
                                            ${ALL_INCLUDE_DIRS}
                                            CPP_IDENTIFIERS
                                            ${CHECK_SOURCES_CPP_IDENTIFIERS})

    endforeach ()

    if (CHECK_SOURCES_FORCE_LANGUAGE)

        set (FORCE_LANGUAGE_OPTION
             FORCE_LANGUAGE ${CHECK_SOURCES_FORCE_LANGUAGE})

    endif (CHECK_SOURCES_FORCE_LANGUAGE)

    # Special rules apply for UTILITY type targets. We need to run
    # the tool PRE_BUILD as opposed to PRE_LINK.
    if (TARGET_TYPE STREQUAL "UTILITY")

        set (WHEN PRE_BUILD)
        set (CUSTOM_COMPILATION_DB_SOURCES ${FILES_TO_CHECK})

    else (TARGET_TYPE STREQUAL "UTILITY")

        # Separate out headers and real sources
        foreach (SOURCE ${FILES_TO_CHECK})

            polysquare_determine_language_for_source (${SOURCE}
                                                      LANGUAGE
                                                      SOURCE_WAS_HEADER
                                                      INCLUDES
                                                      ${ALL_INCLUDE_DIRS})

            if (SOURCE_WAS_HEADER)

                list (APPEND CUSTOM_COMPILATION_DB_SOURCES ${SOURCE})

            endif (SOURCE_WAS_HEADER)

        endforeach ()

    endif (TARGET_TYPE STREQUAL "UTILITY")

    # For mixed source-header targets or UTILITY targets, we need
    # to generate a fake compilation database as CMake won't do it
    # for us in this instance.
    _psq_make_compilation_db (${TARGET}
                              COMPILATION_DB_DIR
                              ${FORCE_LANGUAGE_OPTION}
                              SOURCES
                              ${CUSTOM_COMPILATION_DB_SOURCES}
                              INTERNAL_INCLUDE_DIRS
                              ${CHECK_SOURCES_INTERNAL_INCLUDE_DIRS}
                              EXTERNAL_INCLUDE_DIRS
                              ${CHECK_SOURCES_EXTERNAL_INCLUDE_DIRS}
                              DEFINES
                              ${CHECK_SOURCES_DEFINES})

    # Set the CUSTOM_COMPILATION_DB switch option
    set (CUSTOM_COMPILATION_DB_OPTION
         "-DCUSTOM_COMPILATION_DB_DIR=${COMPILATION_DB_DIR}")


    foreach (SOURCE ${FILES_TO_CHECK})

        get_filename_component (FULL_PATH ${SOURCE} ABSOLUTE)

        # Check if this source is one that requires a custom
        # compilation database
        list (FIND CUSTOM_COMPILATION_DB_SOURCES ${SOURCE} SOURCE_INDEX)

        if (NOT SOURCE_INDEX EQUAL -1)

            set (SOURCE_CUSTOM_COMPILATION_DB_OPTION
                 ${CUSTOM_COMPILATION_DB_OPTION})

        else (NOT SOURCE_INDEX EQUAL -1)

            set (SOURCE_CUSTOM_COMPILATION_DB_OPTION
                 "")

        endif (NOT SOURCE_INDEX EQUAL -1)

        add_custom_command (TARGET ${TARGET}
                            ${WHEN}
                            COMMAND
                            ${CMAKE_COMMAND}
                            -DVERBOSE=${CMAKE_VERBOSE_MAKEFILE}
                            -DALLOW_WARNINGS=${ALLOW_WARNINGS}
                            -DCLANG_TIDY_EXECUTABLE=${CLANG_TIDY_EXECUTABLE}
                            -DENABLE_CHECKS=${CHECK_SOURCES_ENABLE_CHECKS}
                            -DDISABLE_CHECKS=${CHECK_SOURCES_DISABLE_CHECKS}
                            -DSOURCE=${SOURCE}
                            ${SOURCE_CUSTOM_COMPILATION_DB_OPTION}
                            -P
                            ${CLANG_TIDY_EXIT_STATUS_WRAPPER_LOCATION})
    endforeach ()

endfunction ()