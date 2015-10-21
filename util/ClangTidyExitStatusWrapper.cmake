# /util/ClangTidyExitStatusWrapper.cmake
#
# CMake macro to run clang-tidy and and check if there were any warnings
# or errors on stderr. Exits with an error if there is if
# WARN_ONLY is not specified.
#
# See /LICENCE.md for Copyright information
include (CMakeParseArguments)
set (WARN_ONLY FALSE CACHE FORCE "")
set (ENABLE_CHECKS "" CACHE FORCE "")
set (DISABLE_CHECKS "" CACHE FORCE "")
set (CLANG_TIDY_EXECUTABLE "" CACHE FORCE "")
set (SOURCE "" CACHE FORCE "")
set (CUSTOM_COMPILATION_DB_DIR "" CACHE FORCE "")
set (VERBOSE FALSE CACHE FORCE "")

if (NOT CLANG_TIDY_EXECUTABLE)

    message (FATAL_ERROR "CLANG_TIDY_EXECUTABLE was not specified. This is a "
                         "but in ClangTidy.cmake")

endif ()

if (NOT SOURCE)

    message (FATAL_ERROR "SOURCE was not specified. This is a bug in "
                         "ClangTidy.cmake")

endif ()

# Construct checks arguments
set (ALL_CHECKS ${ENABLE_CHECKS})
string (REPLACE "," ";" DISABLE_CHECKS "${DISABLE_CHECKS}")
foreach (CHECK ${DISABLE_CHECKS})

    # Only need a comma after ALL_CHECKS if ALL_CHECKS
    # was set at this point (eg, ENABLE_CHECKS was set)
    if (ALL_CHECKS)

        set (ALL_CHECKS_COMMA ",")

    endif ()

    set (ALL_CHECKS "${ALL_CHECKS}${ALL_CHECKS_COMMA}-${CHECK}")

endforeach ()

if (ALL_CHECKS)

    set (CHECKS_SWITCH "-checks=${ALL_CHECKS}")

endif ()

# Custom compilation DB
if (CUSTOM_COMPILATION_DB_DIR)

    set (CUSTOM_COMPILATION_DB_SWITCH "-p=${CUSTOM_COMPILATION_DB_DIR}")

endif ()

set (CLANG_TIDY_COMMAND_LINE
     "${CLANG_TIDY_EXECUTABLE}"
     ${CHECKS_SWITCH}
     ${CUSTOM_COMPILATION_DB_SWITCH}
     "${SOURCE}")
string (REPLACE ";" " "
        CLANG_TIDY_PRINTED_COMMAND_LINE
        "${CLANG_TIDY_COMMAND_LINE}")

if (VERBOSE)

    message (STATUS ${CLANG_TIDY_PRINTED_COMMAND_LINE})

endif ()

execute_process (COMMAND
                 ${CLANG_TIDY_COMMAND_LINE}
                 RESULT_VARIABLE CLANG_TIDY_RESULT
                 OUTPUT_VARIABLE CLANG_TIDY_OUTPUT
                 ERROR_VARIABLE CLANG_TIDY_ERRORS
                 OUTPUT_STRIP_TRAILING_WHITESPACE
                 ERROR_STRIP_TRAILING_WHITESPACE)

if ("${CLANG_TIDY_OUTPUT}" MATCHES "^.*(error|warning).*$" OR
    NOT CLANG_TIDY_RESULT EQUAL 0)

    message ("${CLANG_TIDY_OUTPUT}")
    message ("${CLANG_TIDY_ERRORS}")

    if (NOT WARN_ONLY)

        message (FATAL_ERROR "Clang-Tidy found problems with your code")

    endif ()

endif ()
