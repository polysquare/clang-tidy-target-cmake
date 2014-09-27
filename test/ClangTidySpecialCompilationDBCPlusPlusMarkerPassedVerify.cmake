# /tests/ClangTidySpecialCompilationDBCPlusPlusMarkerPassedVerify.cmake
# Checks that the generated compilation DB has the specified
# -isystem and -I include dirs.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*Header.h.*-D__cplusplus.*$")