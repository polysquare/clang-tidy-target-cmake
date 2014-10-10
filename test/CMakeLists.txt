# /tests/CMakeLists.txt
# Main entry point for the clang-tidy-target-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif (POLICY CMP0025)
project (ClangTidyTargetCMakeTests)
cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (CLANG_TIDY_RELATIVE_CMAKE_DIRECTORY
     ${CMAKE_CURRENT_SOURCE_DIR}/..)
get_filename_component (CLANG_TIDY_CMAKE_DIRECTORY
                        ${CLANG_TIDY_RELATIVE_CMAKE_DIRECTORY}
                        ABSOLUTE)
set (CMAKE_UNIT_DIRECTORY
     ${CLANG_TIDY_CMAKE_DIRECTORY}/cmake-unit)

set (CLANG_TIDY_INITIAL_CACHE_CONTENTS
     "set (CMAKE_C_COMPILER\n"
     "     ${CMAKE_C_COMPILER}\n"
     "     CACHE STRING \"\" FORCE)\n"
     "set (CMAKE_CXX_COMPILER\n"
     "     ${CMAKE_CXX_COMPILER}\n"
     "     CACHE STRING \"\" FORCE)\n")

set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${CLANG_TIDY_CMAKE_DIRECTORY}
     ${CMAKE_MODULE_PATH})

foreach (PATH ${CMAKE_MODULE_PATH})
     set (CLANG_TIDY_INITIAL_CACHE_CONTENTS
          "${CLANG_TIDY_INITIAL_CACHE_CONTENTS}\n"
          "set (CMAKE_MODULE_PATH ${PATH} \${CMAKE_MODULE_PATH}\n"
          "     CACHE STRING \"\" FORCE)\n")
endforeach ()

# Include ClangTidy to determine whether we can run the tests.
include (ClangTidy)
_validate_clang_tidy (CONTINUE)

if (NOT CONTINUE)

    message (FATAL_ERROR "clang-tidy not found, cannot continue")

endif (NOT CONTINUE)

include (CMakeUnitRunner)

bootstrap_cmake_unit (INITIAL_CACHE_CONTENTS
                      CLANG_TIDY_INITIAL_CACHE_CONTENTS)

add_cmake_test (TurnCMakeExportCompileCommandsOn)

add_cmake_build_test (ClangTidyVersionDetectedOnValidate
                      ClangTidyVersionDetectedOnValidateVerify
                      NO_CLEAN)
add_cmake_build_test (ClangTidyOnTargetSources
                      ClangTidyOnTargetSourcesVerify)
add_cmake_build_test (ClangTidyNoCheckGenerated
                      ClangTidyNoCheckGeneratedVerify)
add_cmake_build_test (ClangTidyCheckGeneratedFlag
                      ClangTidyCheckGeneratedFlagVerify)
add_cmake_build_test (ClangTidyEnableChecks
                      ClangTidyEnableChecksVerify)
add_cmake_build_test (ClangTidyDisableChecks
                      ClangTidyDisableChecksVerify)
add_cmake_build_test (ClangTidyFatalErrorOnWarning
                      ClangTidyFatalErrorOnWarningVerify ALLOW_BUILD_FAIL)
add_cmake_build_test (ClangTidyAllowWarningsOption
                      ClangTidyAllowWarningsOptionVerify)
add_cmake_build_test (ClangTidyGenerateSpecialCompilationDB
                      ClangTidyGenerateSpecialCompilationDBVerify)
add_cmake_build_test (ClangTidyGenerateSpecialCompilationDBForRealTargetHeaders
                      ClangTidyGenerateSpecialCompilationDBForRealTargetHeadersVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBIncludes
                      ClangTidySpecialCompilationDBIncludesVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBDefines
                      ClangTidySpecialCompilationDBDefinesVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCXXFlagsForCPPHeader
                      ClangTidySpecialCompilationDBUseCXXFlagsForCPPHeaderVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCXXCompilerForCPPHeader
                      ClangTidySpecialCompilationDBUseCXXCompilerForCPPHeaderVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCCompilerForCHeader
                      ClangTidySpecialCompilationDBUseCCompilerForCHeaderVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCXXLanguageOptForCPPHeader
                      ClangTidySpecialCompilationDBUseCXXLanguageOptForCPPHeaderVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCLanguageOptForCHeader
                      ClangTidySpecialCompilationDBUseCLanguageOptForCHeaderVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCXXFlagsForCHeaderForceLanguage
                      ClangTidySpecialCompilationDBUseCXXFlagsForCHeaderForceLanguageVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCXXFlagsForCHeaderCPPIdentifiers
                      ClangTidySpecialCompilationDBUseCXXFlagsForCHeaderCPPIdentifiersVerify)
add_cmake_build_test (ClangTidySpecialCompilationDBUseCFlagsForCHeader
                      ClangTidySpecialCompilationDBUseCFlagsForCHeaderVerify)
