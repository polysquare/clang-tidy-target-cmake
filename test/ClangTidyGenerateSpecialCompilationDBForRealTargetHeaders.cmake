# /tests/ClangTidyGenerateSpecialCompilationDBForRealTargetHeaders.cmake
# Add some sources to a compilable target and run clang-tidy on them.
# Headers (which are not compiled) will be added to the target's sources.
# We should put those headers in a separate compilation database so that
# can still check them.
#
# See LICENCE.md for Copyright information

include (${CLANG_TIDY_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
include (${CLANG_TIDY_CMAKE_DIRECTORY}/ClangTidy.cmake)

_validate_clang_tidy (CONTINUE)

set (HEADER_FILE ${CMAKE_CURRENT_BINARY_DIR}/Header.h)
set (CPP_SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Source.cpp)
set (HEADER_FILE_CONTENTS
     "#ifndef HEADER_H\n"
     "#define HEADER_H\n"
     "extern const int i\;\n"
     "#endif")
set (CPP_SOURCE_FILE_CONTENTS
     "#include <Header.h>\n"
     "const int i = 1\;\n"
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n")
set (TARGET executable)

file (WRITE ${HEADER_FILE} ${HEADER_FILE_CONTENTS})
file (WRITE ${CPP_SOURCE_FILE} ${CPP_SOURCE_FILE_CONTENTS})

include_directories (${CMAKE_CURRENT_BINARY_DIR})

add_executable (${TARGET}
                ${CPP_SOURCE_FILE}
                ${HEADER_FILE})
clang_tidy_check_target_sources (${TARGET}
                                 INTERNAL_INCLUDE_DIRS
                                 ${CMAKE_CURRENT_BINARY_DIR}
                                 DISABLE_CHECKS
                                 llvm-*)