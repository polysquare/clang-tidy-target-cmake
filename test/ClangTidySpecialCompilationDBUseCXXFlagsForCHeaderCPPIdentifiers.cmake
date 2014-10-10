# /tests/ClangTidySpecialCompilationDBUseCXXFlagsForCHeaderCPPIdentifiers.cmake
# Add some sources and defines to a custom target
# clang-tidy scan. One of them is a C header, but we pass
# CPP_IDENTIFIERS CLANG_TIDY_IS_CXX and this is defined
# in the source file itself.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (ClangTidy)

_validate_clang_tidy (CONTINUE)

set (HEADER_FILE ${CMAKE_CURRENT_BINARY_DIR}/Header.h)
set (C_SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Source.c)
set (HEADER_FILE_CONTENTS
     "#ifndef HEADER_H\n"
     "#define HEADER_H\n"
     "#define CLANG_TIDY_IS_CXX\n"
     "extern const int i\;\n"
     "#endif")
set (C_SOURCE_FILE_CONTENTS
     "#include <Header.h>\n"
     "const int i = 1\;\n"
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n")
set (TARGET target)

file (WRITE ${HEADER_FILE} ${HEADER_FILE_CONTENTS})
file (WRITE ${C_SOURCE_FILE} ${C_SOURCE_FILE_CONTENTS})

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSING_CXX_DEFINE")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSING_C_DEFINE")

add_custom_target (${TARGET} ALL
                   SOURCES
                   ${C_SOURCE_FILE}
                   ${HEADER_FILE})
clang_tidy_check_target_sources (${TARGET}
                                 INTERNAL_INCLUDE_DIRS
                                 ${CMAKE_CURRENT_BINARY_DIR}
                                 DISABLE_CHECKS
                                 llvm-header-guard
                                 CPP_IDENTIFIERS
                                 CLANG_TIDY_IS_CXX)