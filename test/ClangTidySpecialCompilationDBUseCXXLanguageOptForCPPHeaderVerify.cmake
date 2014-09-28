# /tests/ClangTidySpecialCompilationDBUseCXXLanguageOptForCPPHeader.cmake
# Checks that the generated compilation DB has -x c++ for our header.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*-x c\+\+.*Header.h.*$")