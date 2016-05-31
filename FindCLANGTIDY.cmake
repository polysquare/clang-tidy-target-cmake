# /FindCLANGTIDY.cmake
#
# This CMake script will search for clang-tidy and set the following
# variables
#
# CLANG_TIDY_FOUND : Whether or not clang-tidy is available on the target system
# CLANG_TIDY_VERSION : Version of clang-tidy
# CLANG_TIDY_EXECUTABLE : Fully qualified path to the clang-tidy executable
#
# The following variables will affect the operation of this script
# CLANG_TIDY_SEARCH_PATHS : List of directories to search for clang-tidy in,
#                           before searching any system paths. This should be
#                           the prefix to which clang-tidy was installed, and
#                           not the path that contains the clang-tidy binary.
#                           Eg /opt/ not /opt/bin/
#
# See /LICENCE.md for Copyright information

include ("cmake/tooling-find-pkg-util/ToolingFindPackageUtil")

function (clang_tidy_find)

    # Set-up the directory tree of the clang-tidy installation
    set (BIN_SUBDIR bin)
    set (CLANG_TIDY_EXECUTABLE_NAME clang-tidy)

    # Search for the canonical executable, then search for ones with
    # a version from newest to oldest.
    set (CLANG_TIDY_EXECUTABLE_NAMES clang-tidy
                                     clang-tidy-3.9
                                     clang-tidy-3.8
                                     clang-tidy-3.7
                                     clang-tidy-3.6
                                     clang-tidy-3.5)

    foreach (CLANG_TIDY_EXECUTABLE_NAME ${CLANG_TIDY_EXECUTABLE_NAMES})

        psq_find_tool_executable (${CLANG_TIDY_EXECUTABLE_NAME}
                                  CLANG_TIDY_EXECUTABLE
                                  PATHS ${CLANG_TIDY_SEARCH_PATHS}
                                  PATH_SUFFIXES "${BIN_SUBDIR}")

        if (CLANG_TIDY_EXECUTABLE)

            break ()

        endif ()

    endforeach ()

    psq_report_not_found_if_not_quiet (ClangTidy CLANG_TIDY_EXECUTABLE
                                       "The 'clang-tidy' executable was not"
                                       "found in any search or system"
                                       "paths.\n.."
                                       "Please adjust CLANG_TIDY_SEARCH_PATHS"
                                       "to the installation prefix of the"
                                       "'clang-tidy'\n.. executable or install"
                                       "clang-tidy")

    if (CLANG_TIDY_EXECUTABLE)

        set (CLANG_TIDY_VERSION_HEADER
             "LLVM version ")

        psq_find_tool_extract_version ("${CLANG_TIDY_EXECUTABLE}"
                                       CLANG_TIDY_VERSION
                                       VERSION_ARG --version
                                       VERSION_HEADER
                                       "${CLANG_TIDY_VERSION_HEADER}"
                                       VERSION_END_TOKEN "\n")

    endif ()

    psq_check_and_report_tool_version (ClangTidy
                                       "${CLANG_TIDY_VERSION}"
                                       REQUIRED_VARS
                                       CLANG_TIDY_EXECUTABLE
                                       CLANG_TIDY_VERSION)

    set (CLANG_TIDY_FOUND ${ClangTidy_FOUND} PARENT_SCOPE)

endfunction ()

clang_tidy_find ()
