# /tests/ClangTidyDisableChecksVerify.cmake
# Check that clang-tidy was run with llvm style checks disabled.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*clang-tidy.*-checks=-llvm-.*Source.*$")