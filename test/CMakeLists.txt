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

set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${ACCELERATE_CMAKE_DIRECTORY}
     ${CMAKE_CURRENT_SOURCE_DIR}
     ${CMAKE_MODULE_PATH})

include (CMakeUnitRunner)

bootstrap_cmake_unit (VARIABLES CMAKE_MODULE_PATH
                                CMAKE_GENERATOR
                                CMAKE_C_COMPILER
                                CMAKE_CXX_COMPILER)

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
