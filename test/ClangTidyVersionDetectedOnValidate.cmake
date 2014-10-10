# /tests/ClangTidyVersionDetectedOnValidate.cmake
# Check that CLANG_TIDY_VERSION is set after calling _validate_clang_tidy
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (ClangTidy)

_validate_clang_tidy (CONTINUE)

assert_true (CLANG_TIDY_VERSION)