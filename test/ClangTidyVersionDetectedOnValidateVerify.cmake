# /tests/ClangTidyVersionDetectedOnValidateVerify.cmake
# Check that CONFIGURE.output has "Detected clang-tidy version..."
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (ClangTidy)

set (CONFIGURE_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/CONFIGURE.output)

assert_file_has_line_matching (${CONFIGURE_OUTPUT}
                               "^.*ClangTidy version.*$")