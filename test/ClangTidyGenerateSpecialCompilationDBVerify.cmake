# /tests/ClangTidyGenerateSpecialCompilationDBVerify.cmake
# Check that clang-tidy was run on our Source with its own compilation DB.
# The compilation DB should have the name ${TARGET}_compile_commands.json
# and its structure should look as follows:
#
# [
#     {
#         "directory": ${CMAKE_CURRENT_BINARY_DIR},
#         "command": "${CMAKE_CXX_COMPILER}
#                     -o CMakeFiles/${TARGET}.dir/${SOURCE}.o
#                     -c ${SOURCE}",
#         "file": "${SOURCE}"
#     }
# ]
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (COMMAND "^.*clang-tidy.*-p.*target_compile_commands.*Source.cpp$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${COMMAND})

set (COMPILE_COMMANDS
     ${CMAKE_CURRENT_BINARY_DIR}/target_compile_commands/compile_commands.json)
string (REPLACE "+" "\+" ESCAPED_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*${CMAKE_CURRENT_BINARY_DIR}.*$")
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*${ESCAPED_CXX_COMPILER}.*$")
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*Source.cpp.o.*$")
assert_file_has_line_matching (${COMPILE_COMMANDS}
                               "^.*${CMAKE_CURRENT_BINARY_DIR}/Source.cpp.*$")