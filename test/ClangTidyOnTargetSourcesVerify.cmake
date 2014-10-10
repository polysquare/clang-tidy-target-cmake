# /tests/ClangTidyOnTargetSourcesVerify.cmake
# Check that clang-tidy was run on our Source.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*clang-tidy.*Source.cpp.*$")