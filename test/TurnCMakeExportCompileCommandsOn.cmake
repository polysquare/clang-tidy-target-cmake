# /tests/TurnCMakeExportCompileCommandsOn.cmake
# Check that including ClangTidy.cmake turns CMAKE_EXPORT_COMPILE_COMMANDS ON
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
include (${CLANG_TIDY_CMAKE_DIRECTORY}/ClangTidy.cmake)

assert_true (${CMAKE_EXPORT_COMPILE_COMMANDS})