# /tests/ClangTidyExitStatusWrapper.cmake
# CMake macro to run clang-tidy and and check if there were any warnings
# or errors on stderr. Exits with an error if there is if
# WITH_ERRORS is specified
#
# See LICENCE.md for Copyright information
include (CMakeParseArguments)
set (ALLOW_WARNINGS FALSE CACHE FORCE "")
set (ENABLE_CHECKS "" CACHE FORCE "")
set (CLANG_TIDY_EXECUTABLE "" CACHE FORCE "")
set (SOURCE "" CACHE FORCE "")
set (VERBOSE FALSE CACHE FORCE "")

if (NOT CLANG_TIDY_EXECUTABLE)

    message (FATAL_ERROR "CLANG_TIDY_EXECUTABLE was not specified. This is a "
                         "but in ClangTidy.cmake")

endif (NOT CLANG_TIDY_EXECUTABLE)

if (NOT SOURCE)

    message (FATAL_ERROR "SOURCE was not specified. This is a bug in "
                         "ClangTidy.cmake")

endif (NOT SOURCE)

function (_list_elements_to_comma_separated_list RETURN_LIST)

    set (TO_COMMA_SEP_OPTIONS "")
    set (TO_COMMA_SEP_SINGLEVAR_OPTIONS "")
    set (TO_COMMA_SEP_MULTIVAR_OPTIONS ELEMENTS)

    cmake_parse_arguments (TO_COMMA_SEP
                           "${TO_COMMA_SEP_OPTIONS}"
                           "${TO_COMMA_SEP_SINGLEVAR_OPTIONS}"
                           "${TO_COMMA_SEP_MULTIVAR_OPTIONS}"
                           ${ARGN})

    list (LENGTH TO_COMMA_SEP_ELEMENTS TO_COMMA_SEP_ELEMENTS_LENGTH)

    if (TO_COMMA_SEP_ELEMENTS_LENGTH EQUAL 0)

        return ()

    endif (TO_COMMA_SEP_ELEMENTS_LENGTH EQUAL 0)

    set (COMMA_SEP_LIST "")

    foreach (ELEMENT ${TO_COMMA_SEP_ELEMENTS})

        set (COMMA_SEP_LIST "${COMMA_SEP_LIST}${ELEMENT},")

    endforeach ()

    # Trim the last comma
    string (LENGTH "${COMMA_SEP_LIST}" COMMA_SEP_LIST_LENGTH)
    math (EXPR TRIMMED_COMMA_SEP_LIST_LENGTH
          "${COMMA_SEP_LIST_LENGTH} - 1")
    string (SUBSTRING "${COMMA_SEP_LIST}"
            0 ${TRIMMED_COMMA_SEP_LIST_LENGTH}
            COMMA_SEP_LIST)

    set (${RETURN_LIST} ${COMMA_SEP_LIST} PARENT_SCOPE)

endfunction ()

# Construct enable arguments
_list_elements_to_comma_separated_list (ENABLE_CHECKS_LIST
                                        ELEMENTS ${ENABLE_CHECKS})

if (ENABLE_CHECKS_LIST)

    set (ENABLE_CHECKS_SWITCH "-checks=${ENABLE_CHECKS_LIST}")

endif (ENABLE_CHECKS_LIST)

set (CLANG_TIDY_COMMAND_LINE
     ${CLANG_TIDY_EXECUTABLE}
     ${ENABLE_CHECKS_SWITCH}
     ${SOURCE})
string (REPLACE ";" " "
        CLANG_TIDY_PRINTED_COMMAND_LINE
        "${CLANG_TIDY_COMMAND_LINE}")

if (VERBOSE)

    message (STATUS ${CLANG_TIDY_PRINTED_COMMAND_LINE})

endif (VERBOSE)

execute_process (COMMAND
                 ${CLANG_TIDY_COMMAND_LINE}
                 RESULT_VARIABLE CLANG_TIDY_RESULT
                 OUTPUT_VARIABLE CLANG_TIDY_OUTPUT
                 ERROR_VARIABLE CLANG_TIDY_ERRORS
                 OUTPUT_STRIP_TRAILING_WHITESPACE
                 ERROR_STRIP_TRAILING_WHITESPACE)

if (${CLANG_TIDY_OUTPUT} MATCHES "^.*(error|warning).*$" OR
    NOT CLANG_TIDY_RESULT EQUAL 0)

    message ("${CLANG_TIDY_OUTPUT}")
    message ("${CLANG_TIDY_ERRORS}")

    if (NOT ALLOW_WARNINGS)

        message (FATAL_ERROR "Clang-Tidy found problems with your code")

    endif (NOT ALLOW_WARNINGS)

endif (${CLANG_TIDY_OUTPUT} MATCHES "^.*(error|warning).*$" OR
       NOT CLANG_TIDY_RESULT EQUAL 0)