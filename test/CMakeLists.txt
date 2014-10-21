# /tests/CMakeLists.txt
# Main entry point for the accelerate-target-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif (POLICY CMP0025)
project (AccelerateTargetCMakeTests)
cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (ACCELERATE_RELATIVE_CMAKE_DIRECTORY
     ${CMAKE_CURRENT_SOURCE_DIR}/..)
get_filename_component (ACCELERATE_CMAKE_DIRECTORY
                        ${ACCELERATE_RELATIVE_CMAKE_DIRECTORY}
                        ABSOLUTE)
set (CMAKE_UNIT_DIRECTORY
     ${ACCELERATE_CMAKE_DIRECTORY}/cmake-unit)

set (ACCELERATE_INITIAL_CACHE_CONTENTS
     "set (CMAKE_C_COMPILER\n"
     "     ${CMAKE_C_COMPILER}\n"
     "     CACHE STRING \"\" FORCE)\n"
     "set (CMAKE_CXX_COMPILER\n"
     "     ${CMAKE_CXX_COMPILER}\n"
     "     CACHE STRING \"\" FORCE)\n"
     "set (CMAKE_GENERATOR\n"
     "     \"${CMAKE_GENERATOR}\"\n"
     "     CACHE STRING \"\" FORCE)\n")


set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${ACCELERATE_CMAKE_DIRECTORY}
     ${CMAKE_MODULE_PATH})

foreach (PATH ${CMAKE_MODULE_PATH})
     set (ACCELERATE_INITIAL_CACHE_CONTENTS
          "${ACCELERATE_INITIAL_CACHE_CONTENTS}\n"
          "set (CMAKE_MODULE_PATH ${PATH} \${CMAKE_MODULE_PATH}\n"
          "     CACHE STRING \"\" FORCE)\n")
endforeach ()

include (CMakeUnitRunner)

bootstrap_cmake_unit (INITIAL_CACHE_CONTENTS
                      ACCELERATE_INITIAL_CACHE_CONTENTS)

add_cmake_test (NoPCHOption)
add_cmake_test (NoUnityBuildOption)
add_cmake_test (PCHTargetsGeneratedAfterAcceleratingTarget)
add_cmake_test (UnityBuildTargetsGeneratedAfterAcceleratingTarget)
add_cmake_test (PrefixHeaderClearedOnTarget)
add_cmake_build_test (SkipGeneratedFilesInPCHFile
                      SkipGeneratedFilesInPCHFileVerify)
add_cmake_build_test (UseFilesInBuildDirectoryInPCHFile
                      UseFilesInBuildDirectoryInPCHFileVerify)
add_cmake_build_test (UnityBuildTargetsDependOnUnityDependencies
                      UnityBuildTargetsDependOnUnityDependenciesVerify
                      TARGET all_unity)
add_cmake_build_test (UnityBuildTargetsInheritDependencies
                      UnityBuildTargetsInheritDependenciesVerify
                      TARGET all_unity)
add_cmake_build_test (UnityBuildTargetsInheritTargetLinkLibraries
                      UnityBuildTargetsInheritTargetLinkLibrariesVerify
                      TARGET all_unity)
