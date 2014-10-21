# /test/PrefixHeaderClearedOnTarget.cmake
#
# Tests that the COTIRE_PREFIX_HEADER_IGNORE_PATH property is cleared
# on accelerated targets
#
# See LICENCE.md for Copyright information.

include (AccelerateTarget)
include (CMakeUnit)

set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)

set (SOURCE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp)
set (SOURCE_FILE_CONTENTS
     "int main ()\n"
     "{\n"
     "    return 0;\n"
     "}\n")
file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

set (EXECUTABLE executable)
add_executable (${EXECUTABLE} ${SOURCE_FILE})

psq_accelerate_target (${EXECUTABLE})

assert_has_property_with_value (TARGET ${EXECUTABLE}
                                COTIRE_PREFIX_HEADER_IGNORE_PATH
                                STRING EQUAL "")
