# /tests/ClangTidyCheckGeneratedFlagVerify.cmake
# Check that clang-tidy was run on generated sources when CHECK_GENERATED
# is specified.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*clang-tidy .*Source.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*clang-tidy .*Generated.cpp.*$")