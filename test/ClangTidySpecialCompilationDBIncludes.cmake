# /tests/ClangTidySpecialCompilationDBIncludes.cmake
# Add some sources and includes to a custom target
# clang-tidy scan. The includes should be passed into
# the compilation DB.
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
set (SOURCE_INTERNAL_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/internal)
set (SOURCE_EXTERNAL_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/external)
set (TARGET target)

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

add_custom_target (${TARGET} ALL
                   SOURCES ${SOURCE_FILE})
clang_tidy_check_target_sources (${TARGET}
                                 INTERNAL_INCLUDE_DIRS
                                 ${SOURCE_INTERNAL_INCLUDE_DIRS}
                                 EXTERNAL_INCLUDE_DIRS
                                 ${SOURCE_EXTERNAL_INCLUDE_DIRS})