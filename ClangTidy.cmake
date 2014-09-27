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

function (clang_tidy_check_target_sources TARGET)

    set (CHECK_SOURCES_OPTIONS
         CHECK_GENERATED
         ALLOW_WARNINGS
         USE_OWN_COMPILATION_DB)
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

    # Special rules apply for UTILITY type targets. We need to run
    # the tool PRE_BUILD as opposed to PRE_LINK and we also need
    # to generate a fake compilation database as CMake won't do it
    # for us in this instance.
    if (TARGET_TYPE STREQUAL "UTILITY")

        set (WHEN PRE_BUILD)
        set (COMPILATION_DB_DIR
             ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_compile_commands/)
        set (COMPILATION_DB_FILE
             ${COMPILATION_DB_DIR}/compile_commands.json)

        set (COMPILATION_DB_FILE_CONTENTS
             "[")

        foreach (SOURCE ${FILES_TO_CHECK})

            get_filename_component (FULL_PATH ${SOURCE} ABSOLUTE)
            get_filename_component (BASENAME ${SOURCE} NAME)

            set (LANGUAGE ${CHECK_SOURCES_FORCE_LANGUAGE})
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
            foreach (INTERNAL_INCLUDE ${CHECK_SOURCES_INTERNAL_INCLUDE_DIRS})

                set (COMPILATION_DB_FILE_CONTENTS
                     "${COMPILATION_DB_FILE_CONTENTS} -I${INTERNAL_INCLUDE}")

            endforeach ()

            foreach (EXTERNAL_INCLUDE ${CHECK_SOURCES_EXTERNAL_INCLUDE_DIRS})

                set (COMPILATION_DB_FILE_CONTENTS
                     "${COMPILATION_DB_FILE_CONTENTS}"
                     "-isystem${EXTERNAL_INCLUDE}")

            endforeach ()

            # All defines
            foreach (DEFINE ${CHECK_SOURCES_DEFINES})

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

        # Set the CUSTOM_COMPILATION_DB switch option
        set (CUSTOM_COMPILATION_DB_OPTION
             "-DCUSTOM_COMPILATION_DB_DIR=${COMPILATION_DB_DIR}")

    endif (TARGET_TYPE STREQUAL "UTILITY")

    foreach (SOURCE ${FILES_TO_CHECK})

        get_filename_component (FULL_PATH ${SOURCE} ABSOLUTE)
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
                            ${CUSTOM_COMPILATION_DB_OPTION}
                            -P
                            ${CLANG_TIDY_EXIT_STATUS_WRAPPER_LOCATION})
    endforeach ()

endfunction ()