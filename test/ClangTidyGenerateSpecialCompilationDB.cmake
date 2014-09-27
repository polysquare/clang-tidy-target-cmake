# /tests/ClangTidyGenerateSpecialCompilationDB.cmake
# Add some sources and run clang-tidy on them, but add them to a
# UTILITY type target. This will cause our own target-specific
# compilation DB to be generated.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
include (${CLANG_TIDY_CMAKE_DIRECTORY}/ClangTidy.cmake)

_validate_clang_tidy (CONTINUE)

set (SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Source.cpp)
set (SOURCE_FILE_CONTENTS
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n")
set (TARGET target)

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

add_custom_target (${TARGET} ALL
                   SOURCES ${SOURCE_FILE})
clang_tidy_check_target_sources (${TARGET})