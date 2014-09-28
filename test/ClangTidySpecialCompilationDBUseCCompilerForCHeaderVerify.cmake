# /tests/ClangTidySpecialCompilationDBUseCCompilerForCHeaderVerify.cmake
# Checks that the generated compilation DB has ${CMAKE_C_COMPILER} for
# Header.h
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
message ("C Compiler ${CMAKE_CURRENT_BINARY_DIR}")
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*${CMAKE_C_COMPILER}.*Header.h.*$")