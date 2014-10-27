# /test/UnityBuildTargetsInheritTargetLinkLibraries.cmake
# Verifies the generated _unity target inherits all external target link
# libraries
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

set (LIBRARY library)

file (WRITE ${LIBRARY_SOURCE_FILE} ${LIBRARY_SOURCE_FILE_CONTENTS})

# Add library, but do not accelerate it
add_library (${LIBRARY} STATIC ${LIBRARY_SOURCE_FILE})

# Set up main source file for unity build
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
target_link_libraries (${EXECUTABLE} ${LIBRARY})
psq_accelerate_target (${EXECUTABLE})

set (EXECUTABLE_UNITY ${EXECUTABLE}_unity)

assert_target_is_linked_to (${EXECUTABLE_UNITY} ${LIBRARY})
