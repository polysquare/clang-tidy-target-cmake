# /tests/TurnCMakeExportCompileCommandsOn.cmake
# Check that including ClangTidy.cmake turns CMAKE_EXPORT_COMPILE_COMMANDS ON
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (ClangTidy)

assert_true (${CMAKE_EXPORT_COMPILE_COMMANDS})