# /CMakeLists.txt
#
# Main entry point for ClangTidy tests.
#
# See /LICENCE.md for Copyright information

include ("${CMAKE_CURRENT_LIST_DIR}/conanbuildinfo.cmake")
set (CMAKE_MODULE_PATH
     ${CONAN_CMAKE_MODULE_PATH}  # NOLINT:correctness/quotes
     ${CMAKE_MODULE_PATH})  # NOLINT:correctness/quotes

cmake_minimum_required (VERSION 2.8)

set (_CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}")

set (CMAKE_MODULE_PATH
     "${CMAKE_MODULE_PATH}"
     "${CMAKE_CURRENT_LIST_DIR}")

include ("cmake/cmake-module-common/Common" OPTIONAL)
include (ClangTidy)

if (NOT CMAKE_SCRIPT_MODE_FILE)

    clang_tidy_validate (HAVE_CLANG_TIDY)

else ()

    set (HAVE_CLANG_TIDY TRUE)

endif ()

function (clang_tidy_phase_has_error_or_output_matching)

    list (GET CALLER_ARGN 0 PHASE)
    list (GET CALLER_ARGN 1 REGEX)
    list (GET CALLER_ARGN 2 RESULT_VARIABLE)

    # Once we've looked at CALLER_ARGN, set it to include the
    # BINARY_DIR and SOURCE_DIR so that cmake_unit_get_log_for can
    # use it
    set (CALLER_ARGN
         BINARY_DIR "${BINARY_DIR}"
         SOURCE_DIR "${SOURCE_DIR}")

    set (${RESULT_VARIABLE}
         "contents of ${PHASE} error and output to match ${REGEX}"
         PARENT_SCOPE)

    cmake_unit_get_log_for (${PHASE} OUTPUT ${PHASE}_OUTPUT)
    cmake_unit_get_log_for (${PHASE} ERROR ${PHASE}_ERROR)

    file (READ "${${PHASE}_OUTPUT}" ${PHASE}_OUTPUT_CONTENTS)
    file (READ "${${PHASE}_ERROR}" ${PHASE}_ERROR_CONTENTS)
    file (WRITE "${BINARY_DIR}/${PHASE}_ALL"
          "${${PHASE}_OUTPUT_CONTENTS}"
          "${${PHASE}_ERROR_CONTENTS}")

    cmake_unit_eval_matcher ("${BINARY_DIR}/${PHASE}_ALL"
                             file_contents
                             any_line
                             matches_regex
                             "${REGEX}"
                             RESULT)

    if (RESULT STREQUAL "TRUE")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# Check that specifying WARN_ONLY on the clang-tidy command
# allows warnings to go through without fatal errors.
function (clang_tidy_test_allow_warnings_option)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (EXECUTABLE executable)
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    PREPEND_CONTENTS
                                                    "int main (void)"
                                                    "{"
                                                    "    int *a = 0@SEMICOLON@"
                                                    "    return *a@SEMICOLON@"
                                                    "}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        add_executable ("${EXECUTABLE}"
                        "${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}" WARN_ONLY)

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_assert_that (INVOKE_BUILD
                                not phase_has_error_or_output_matching
                                "^.*Clang-Tidy found prob.* with your code.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and run clang-tidy on them, checking generated files
# as indicated
function (clang_tidy_test_check_generated_flag)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (EXECUTABLE executable)
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME "Generated.cpp"
                                                      FUNCTIONS "main")

        add_executable ("${EXECUTABLE}"
                        "${BINARY_DIR}/Generated.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}" CHECK_GENERATED)

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*clang-tidy.* .*Generated.cpp.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and run clang-tidy on them, disabling
# the llvm style checks explicitly.
function (clang_tidy_test_disable_checks)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (EXECUTABLE executable)
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}" DISABLE_CHECKS llvm-*)

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*clang-tidy.*-checks=-llvm-.*Source.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and run clang-tidy on them, enabling
# the google style checks explicitly.
function (clang_tidy_test_enable_checks)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}" ENABLE_CHECKS google*)

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*clang-tidy.*-checks=google.*Source.cpp.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources with a clang-tidy warning in them
# (no matching // namespace foo on }) and run
# clang-tidy on them.
function (clang_tidy_test_fatal_error_on_warning)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    PREPEND_CONTENTS
                                                    "int main (void)"
                                                    "{"
                                                    "    int *a = 0@SEMICOLON@"
                                                    "    return *a@SEMICOLON@"
                                                    "}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_assert_that (INVOKE_BUILD phase_has_error_or_output_matching
                                "^.*Clang-Tidy found prob.* with your code.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   INVOKE_BUILD OPTIONS ALLOW_FAIL
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and run clang-tidy on them, but add them to a
# UTILITY type target. This will cause our own target-specific
# compilation DB to be generated.
function (clang_tidy_test_generate_comp_db)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (TARGET target)
        add_custom_target (${TARGET} ALL SOURCES "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources (${TARGET})

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (COMMAND "^.*clang-tidy.*-p.*target_compile_commands.*Source.cpp$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${COMMAND})
        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        string (REPLACE "+" "\\+" ESCAPED_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
        cmake_unit_assert_that (${COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*${BINARY_DIR}.*$")
        cmake_unit_assert_that (${COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*${ESCAPED_CXX_COMPILER}.*$")
        cmake_unit_assert_that (${COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*Source.cpp.o.*$")
        cmake_unit_assert_that (${COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*${SOURCE_DIR}/Source.cpp.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources to a compilable target and run clang-tidy on them.
# Headers (which are not compiled) will be added to the target's sources.
# We should put those headers in a separate compilation database so that
# can still check them.
function (clang_tidy_test_generate_comp_db_for_real_target_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    INCLUDES "Header.h"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")
        add_executable (${TARGET}
                        "${SOURCE_DIR}/Source.cpp"
                        "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS "${SOURCE_DIR}"
                                         DISABLE_CHECKS
                                         llvm-*)

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (SOURCE_COMMAND "^.*clang-tidy.*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${SOURCE_COMMAND})
        set (HEADER_COMMAND
             "^.*clang-tidy.*-p.*target_compile_commands.*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                ${HEADER_COMMAND})
        set (MAIN_COMPILE_COMMANDS
             "${BINARY_DIR}/compile_commands.json")
        cmake_unit_assert_that (${MAIN_COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*${SOURCE_DIR}/Source.cpp.*$")
        set (AUX_COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${AUX_COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*${SOURCE_DIR}/Header.h.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (PRECONFIGURE OPTIONS
                                                SKIP_GENERATOR_REGEX
                                                "^Visual.*|^XCode.*|^NMake.*"
                                   INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and run clang-tidy on them, but don't check
# generated sources by default.
function (clang_tidy_test_no_check_generated)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (EXECUTABLE executable)
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME "Generated.cpp"
                                                      FUNCTIONS "generated")
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp"
                        "${BINARY_DIR}/Generated.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*clang-tidy.* .*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                "^.*clang-tidy.* .*Generated.cpp$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and run clang-tidy on them.
function (clang_tidy_test_on_target_sources)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*clang-tidy.*Source.cpp.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. The defines should be passed into
# the compilation DB.
function (clang_tidy_test_comp_db_defines)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (TARGET target)
        add_custom_target (${TARGET} ALL SOURCES "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources (${TARGET}
                                         DEFINES custom_define=1)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*-Dcustom_define=1.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and includes to a custom target
# clang-tidy scan. The includes should be passed into
# the compilation DB.
function (clang_tidy_test_comp_db_includes)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (INTERNAL_INCLUDE_DIRS "${SOURCE_DIR}/internal")
        set (EXTERNAL_INCLUDE_DIRS "${SOURCE_DIR}/external")
        set (TARGET target)
        add_custom_target (${TARGET} ALL SOURCES "${SOURCE_DIR}/Source.cpp")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS
                                         ${INTERNAL_INCLUDE_DIRS}
                                         EXTERNAL_INCLUDE_DIRS
                                         ${EXTERNAL_INCLUDE_DIRS})

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*-isystem.*external.*$")
        cmake_unit_assert_that (${COMPILE_COMMANDS}
                                file_contents
                                any_line
                                matches_regex
                                "^.*-I.*internal.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C header.
function (clang_tidy_test_comp_db_use_c_compiler_for_c_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.c"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")
        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.c"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS
                                         "${SOURCE_DIR}"
                                         DISABLE_CHECKS
                                         llvm-header-guard)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*${CMAKE_C_COMPILER}.*Header.h.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C header. The CMAKE_C_FLAGS
# should be part of its compile commands.
function (clang_tidy_test_comp_db_use_c_flags_for_c_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.c"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.c"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS
                                         "${SOURCE_DIR}"
                                         DISABLE_CHECKS
                                         llvm-header-guard)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS}
                                file_contents any_line matches_regex
                                "^.*Header.h.*-DUSING_C_DEFINE.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C header.
function (clang_tidy_test_comp_db_use_c_language_opt_for_c_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.c"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.c"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS
                                         "${SOURCE_DIR}"
                                         DISABLE_CHECKS
                                         llvm-header-guard)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} not file_contents any_line
                                matches_regex
                                "^.*-x c\\+\\+.*Header.h.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C++ header.
function (clang_tidy_test_comp_db_use_cxx_compiler_for_cpp_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.cpp"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS
                                         "${SOURCE_DIR}"
                                         DISABLE_CHECKS
                                         llvm-header-guard)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        string (REPLACE "+" "\\+" ESCAPED_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*${ESCAPED_CXX_COMPILER}.*Header.h.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C header, but we pass
# CPP_IDENTIFIERS CLANG_TIDY_IS_CXX and this is defined
# in the source file itself.
function (clang_tidy_test_comp_db_use_cxx_flags_for_c_header_cpp_identifiers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    DEFINES
                                                    CLANG_TIDY_IS_CXX
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.c"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.c"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS
                                         "${SOURCE_DIR}"
                                         DISABLE_CHECKS
                                         llvm-header-guard
                                         CPP_IDENTIFIERS
                                         CLANG_TIDY_IS_CXX)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*Header.h.*-DUSING_CXX_DEFINE.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C header, but we pass
# FORCE_LANGUAGE CXX.
function (clang_tidy_test_comp_db_use_cxx_flags_for_c_header_force_language)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.c"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.c"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS "${SOURCE_DIR}"
                                         DISABLE_CHECKS llvm-header-guard
                                         FORCE_LANGUAGE CXX)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*Header.h.*-DUSING_CXX_DEFINE.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C++ header. The CMAKE_CXX_FLAGS
# should be part of its compile commands.
function (clang_tidy_test_comp_db_use_cxx_flags_for_cpp_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.cpp"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS "${SOURCE_DIR}"
                                         DISABLE_CHECKS llvm-header-guard)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*Header.h.*-DUSING_CXX_DEFINE.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C++ header.
function (clang_tidy_test_comp_db_use_cxx_language_opt_for_cpp_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        set (TARGET target)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    INCLUDES "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${SOURCE_DIR}")

        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

        add_custom_target (${TARGET} ALL
                           SOURCES "${SOURCE_DIR}/Source.cpp"
                                   "${SOURCE_DIR}/Header.h")
        clang_tidy_check_target_sources (${TARGET}
                                         INTERNAL_INCLUDE_DIRS "${SOURCE_DIR}"
                                         DISABLE_CHECKS llvm-header-guard)

    endfunction ()

    function (clang_tidy_verify)

        set (COMPILE_COMMANDS
             "${BINARY_DIR}/target_compile_commands/compile_commands.json")
        cmake_unit_assert_that (${COMPILE_COMMANDS} file_contents any_line
                                matches_regex
                                "^.*-x c\\+\\+.*Header.h.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Check that CLANG_TIDY_VERSION is set after calling clang_tidy_validate
function (clang_tidy_test_version_detected_on_validate)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (clang_tidy_configure)

        cmake_unit_assert_that (CLANG_TIDY_VERSION
                                not variable_is STRING EMPTY EMPTY)

    endfunction ()

    function (clang_tidy_verify)

        cmake_unit_get_log_for (INVOKE_CONFIGURE OUTPUT CONFIGURE_OUTPUT)
        cmake_unit_assert_that (${CONFIGURE_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*Found ClangTidy.*version.*$")

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND clang_tidy_configure
                                   VERIFY COMMAND clang_tidy_verify)

    endif ()

endfunction ()

# Check that including ClangTidy.cmake turns CMAKE_EXPORT_COMPILE_COMMANDS ON
function (clang_tidy_test_turn_c_make_export_compile_commands_on)

    function (clang_tidy_configure)

        cmake_unit_assert_that (CMAKE_EXPORT_COMPILE_COMMANDS is_true)

    endfunction ()

    if (HAVE_CLANG_TIDY)

        cmake_unit_configure_config_only_test (CONFIGURE
                                               COMMAND clang_tidy_configure)

    endif ()

endfunction ()

function (clang_tidy_test_where_unavailable)

    if (NOT HAVE_CLANG_TIDY)

        cmake_unit_configure_config_only_test ()

    endif ()

endfunction ()


cmake_unit_register_matcher_namespace (clang_tidy)

set (UTIL_DIR "${CMAKE_CURRENT_LIST_DIR}/util")
set (CMAKE_FILES "${CMAKE_CURRENT_LIST_DIR}/ClangTidy.cmake"
                 "${CMAKE_CURRENT_LIST_DIR}/FindCLANGTIDY.cmake"
                 "${UTIL_DIR}/ClangTidyExitStatusWrapper.cmake")
set (MARKDOWN_FILES
     "${CMAKE_CURRENT_LIST_DIR}/LICENCE.md"
     "${CMAKE_CURRENT_LIST_DIR}/README.md")

if (COMMAND cmake_module_add_common_targets)

    cmake_module_add_common_targets (NAMESPACE "clang_tidy"
                                     CMAKE_FILES ${CMAKE_FILES}
                                     DOCUMENTATION_FILES ${MARKDOWN_FILES})

endif ()
