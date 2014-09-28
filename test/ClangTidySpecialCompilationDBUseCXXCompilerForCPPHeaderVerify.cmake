# /tests/ClangTidySpecialCompilationDBUseCXXCompilerForCPPHeader.cmake
# Checks that the generated compilation DB has ${CMAKE_CXX_COMPILER} for our
# header.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
string (REPLACE "+" "\+" ESCAPED_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*${ESCAPED_CXX_COMPILER}.*Header.h.*$")