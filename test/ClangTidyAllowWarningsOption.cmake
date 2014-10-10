# /tests/ClangTidyAllowWarningsOption.cmake
# Check that specifying ALLOW_WARNINGS on the clang-tidy command
# allows warnings to go through without fatal errors.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (ClangTidy)

_validate_clang_tidy (CONTINUE)

set (SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Source.cpp)
set (SOURCE_FILE_CONTENTS
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n"
     "namespace foo {\n"
     "}\n")
set (EXECUTABLE executable)

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

add_executable (${EXECUTABLE} ${SOURCE_FILE})
clang_tidy_check_target_sources (${EXECUTABLE}
                                 WARN_ONLY)