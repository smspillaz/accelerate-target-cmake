# /test/UnityBuildTargetsInheritDependencies.cmake
# Verifies the generated _unity target inherits all non-library
# dependencies
#
# See LICENCE.md for Copyright information.

include (AccelerateTarget)
include (CMakeUnit)

set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)

# Set up a custom target to write 'o' every single time it is run
set (CUSTOM_COMMAND_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/custom_command_output)
file (REMOVE ${CUSTOM_COMMAND_OUTPUT})
add_custom_command (OUTPUT ${CUSTOM_COMMAND_OUTPUT}
                    COMMAND ${CMAKE_COMMAND} -E touch ${CUSTOM_COMMAND_OUTPUT})

set (CUSTOM_TARGET_NAME custom_target)
add_custom_target (${CUSTOM_TARGET_NAME}
                   SOURCES ${CUSTOM_COMMAND_OUTPUT})

set (SOURCE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp)

set (SOURCE_FILE_CONTENTS
     "int main ()\n"
     "{\n"
     "    return 0\;\n"
     "}\n")
file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

set (EXECUTABLE executable)

add_executable (${EXECUTABLE} ${SOURCE_FILE})
add_dependencies (${EXECUTABLE} ${CUSTOM_TARGET_NAME})

psq_accelerate_target (${EXECUTABLE} DEPENDS ${CUSTOM_TARGET_NAME})
