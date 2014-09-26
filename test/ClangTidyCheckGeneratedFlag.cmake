# /tests/ClangTidyCheckGeneratedFlag.cmake
# Add some sources and run clang-tidy on them, but don't check
# generated sources by default.
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
set (GENERATED_SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Generated.cpp)
set (EXECUTABLE executable)

add_custom_command (OUTPUT ${GENERATED_SOURCE_FILE}
                    COMMAND
                    ${CMAKE_COMMAND} -E touch ${GENERATED_SOURCE_FILE}) 

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})
add_executable (${EXECUTABLE} ${SOURCE_FILE} ${GENERATED_SOURCE_FILE})
clang_tidy_check_target_sources (${EXECUTABLE} CHECK_GENERATED)