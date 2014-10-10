# /tests/ClangTidyAllowWarningsOptionVerify.cmake
# Check that specifying ALLOW_WARNINGS on the clang-tidy command
# allows warnings to go through without fatal errors.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (READ ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output BUILD_OUTPUT)
file (READ ${CMAKE_CURRENT_BINARY_DIR}/BUILD.error BUILD_ERROR)

file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/BUILD_ALL "${BUILD_OUTPUT}")
file (APPEND ${CMAKE_CURRENT_BINARY_DIR}/BUILD_ALL "${BUILD_ERROR}")

set (BUILD_ALL ${CMAKE_CURRENT_BINARY_DIR}/BUILD_ALL)

assert_file_does_not_have_line_matching (${BUILD_ALL}
                                         "^.*Clang-Tidy found problems with your code.*$")