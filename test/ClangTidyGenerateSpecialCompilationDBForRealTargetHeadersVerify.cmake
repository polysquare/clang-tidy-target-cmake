# /tests/ClangTidyGenerateSpecialCompilationDBForRealTargetHeadersVerify.cmake
# Check that clang-tidy was run on our Header with its own compilation DB.
# The source should be found in the main compilation DB and the header is
# to be found in
# ${CMAKE_CURRENT_BINARY_DIR}/executable_compile_commands/compile_commands.json
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (SOURCE_COMMAND
     "^.*clang-tidy.*Source.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${SOURCE_COMMAND})

set (HEADER_COMMAND
     "^.*clang-tidy.*-p.*executable_compile_commands.*Header.h.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${HEADER_COMMAND})

set (MAIN_COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json)
assert_file_has_line_matching (${MAIN_COMPILE_COMMANDS}
                               "^.*${CMAKE_CURRENT_BINARY_DIR}/Source.cpp.*$")

set (AUX_COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/executable_compile_commands/compile_commands.json)
assert_file_has_line_matching (${AUX_COMPILE_COMMANDS}
                               "^.*${CMAKE_CURRENT_BINARY_DIR}/Header.h.*$")