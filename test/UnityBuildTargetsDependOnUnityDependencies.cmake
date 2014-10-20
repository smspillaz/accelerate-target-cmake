# /test/UnityBuildTargetsDependOnUnityDependencies.cmake
# Verifies the generated _unity target depends on the _unity version
# of other targets where those exists.
#
# See LICENCE.md for Copyright information.

include (AccelerateTarget)
include (CMakeUnit)

set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)

set (LIBRARY_SOURCE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/LibrarySource.c)
set (LIBRARY_SOURCE_FILE_CONTENTS
     "int function ()\n"
     "{\n"
     "    return 1\;\n"
     "}\n")
file (WRITE ${LIBRARY_SOURCE_FILE} ${LIBRARY_SOURCE_FILE_CONTENTS})

set (LIBRARY library)

include_directories (${CMAKE_CURRENT_SOURCE_DIR})

add_library (${LIBRARY} SHARED ${LIBRARY_SOURCE_FILE})
psq_accelerate_target (${LIBRARY})

# Set up main source file for unity build
set (EXECUTABLE_SOURCE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp)
set (EXECUTABLE_SOURCE_FILE_CONTENTS
     "int main ()\n"
     "{\n"
     "    return 0\;\n"
     "}\n")
file (WRITE ${EXECUTABLE_SOURCE_FILE} ${EXECUTABLE_SOURCE_FILE_CONTENTS})

set (EXECUTABLE executable)

add_executable (${EXECUTABLE} ${EXECUTABLE_SOURCE_FILE})
target_link_libraries (${EXECUTABLE} ${LIBRARY})
psq_accelerate_target (${EXECUTABLE})

set (EXECUTABLE_UNITY ${EXECUTABLE}_unity)
set (LIBRARY_UNITY ${LIBRARY}_unity)

assert_target_is_linked_to (${EXECUTABLE_UNITY} ${LIBRARY_UNITY})
