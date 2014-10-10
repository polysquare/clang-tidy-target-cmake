# /tests/ClangTidyDisableChecks.cmake
# Add some sources and run clang-tidy on them, disabling
# the llvm style checks explicitly.
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
     "}\n")
set (EXECUTABLE executable)

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

add_executable (${EXECUTABLE} ${SOURCE_FILE})
clang_tidy_check_target_sources (${EXECUTABLE}
                                 DISABLE_CHECKS
                                 llvm-*)