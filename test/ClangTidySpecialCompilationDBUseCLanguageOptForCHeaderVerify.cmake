# /tests/ClangTidySpecialCompilationDBUseCLanguageOptForCHeaderVerify.cmake
# Checks that the generated compilation DB does not have -x c++ for our header.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
message ("C Compiler ${CMAKE_CURRENT_BINARY_DIR}")
assert_file_does_not_have_line_matching (${COMPILE_COMMANDS}
                                         "^.*-x c\+\+.*Header.h.*$")