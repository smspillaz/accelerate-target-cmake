# /test/NoUnityBuildOption.cmake
# Verifies that passing NO_UNITY_BUILD causes unity targets not to be generated.
#
# See LICENCE.md for Copyright information.

include (AccelerateTarget)
include (CMakeUnit)

set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)

set (SOURCE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp)

set (SOURCE_FILE_CONTENTS
     "int main ()\n"
     "{\n"
     "    return 0\;\n"
     "}\n")
file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

set (EXECUTABLE executable)

include_directories (${CMAKE_CURRENT_SOURCE_DIR})
add_executable (${EXECUTABLE} ${SOURCE_FILE})
psq_accelerate_target (${EXECUTABLE} NO_UNITY_BUILD)

assert_target_does_not_exist (${EXECUTABLE}_unity)
