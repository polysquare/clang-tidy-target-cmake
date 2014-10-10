# /tests/ClangTidyNoCheckGeneratedVerify.cmake
# Check that clang-tidy was run only run on the non-generated sources.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*clang-tidy .*Source.cpp.*$")
assert_file_does_not_have_line_matching (${BUILD_OUTPUT}
                                         "^.*clang-tidy .*Generated.cpp$")
