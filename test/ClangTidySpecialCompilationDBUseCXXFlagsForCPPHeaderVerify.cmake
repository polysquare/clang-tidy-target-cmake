# /tests/ClangTidySpecialCompilationDBUseCXXFlagsForCPPHeaderVerify.cmake
# Checks that the generated compilation DB has -DUSING_CXX_DEFINE for our
# C++ Header.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*Header.h.*-DUSING_CXX_DEFINE.*$")