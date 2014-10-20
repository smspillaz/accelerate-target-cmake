# /AccelerateTarget.cmake
# CMake macro which provides a function called psq_accelerate_target, which
# effectively sets up cotire on it, handles linking requirements between unity
# builds, and adds the correct dependencies to the unity build target.
#
# See LICENCE.md for Copyright information

set (CMAKE_MODULE_PATH
     ${CMAKE_MODULE_PATH}
     ${CMAKE_CURRENT_LIST_DIR}/tooling-cmake-util
     ${CMAKE_CURRENT_LIST_DIR}/parallel-build-target-utils/
     ${CMAKE_CURRENT_LIST_DIR}/cotire/CMake)

include (cotire)
include (ParallelBuildTargetUtils)
include (PolysquareToolingUtil)

# psq_accelerate_target:
#
# For a target TARGET, adds a prefix header with all found headers used
# in this TARGET, cause it to be included when building TARGET and precompile
# the prefix header before building TARGET. Also adds a new target
# TARGET_unity with a single-source file which includes every other source
# file in one compilation unit.
#
# The TARGET_unity target will be set up to depend on any libraries this
# TARGET links to, and will prefer _unity versions of those libraries if
# available.
#
# TARGET: Target to accelerate
# [Optional] NO_UNITY_BUILD: Don't generate TARGET_unity
# [Optional] NO_PRECOMPILED_HEADERS: Don't generate a precompiled header
# [Optional] DEPENDS: Dependencies of this TARGET to add to TARGET_unity
function (psq_accelerate_target TARGET)

    set (ACCELERATE_OPTION_ARGS
         NO_UNITY_BUILD
         NO_PRECOMPILED_HEADERS)
    set (ACCELERATE_SINGLEVAR_ARGS
         "")
    set (ACCELERATE_MULTIVAR_ARGS
         DEPENDS)

    cmake_parse_arguments (ACCELERATION
                           "${ACCELERATE_OPTION_ARGS}"
                           "${ACCELERATE_SINGLEVAR_ARGS}"
                           "${ACCELERATE_MULTIVAR_ARGS}"
                           ${ARGN})

    set (COTIRE_PROPERTIES)
    psq_add_switch (COTIRE_PROPERTIES
                    ACCELERATION_NO_UNITY_BUILD
                    ON "COTIRE_ADD_UNITY_BUILD OFF"
                    OFF "COTIRE_ADD_UNITY_BUILD ON")
    psq_add_switch (COTIRE_PROPERTIES
                    ACCELERATION_NO_PRECOMPILED_HEADERS
                    ON "COTIRE_ENABLE_PRECOMPILED_HEADER OFF"
                    OFF "COTIRE_ENABLE_PRECOMPILED_HEADER ON")
    string (REPLACE " " ";" COTIRE_PROPERTIES "${COTIRE_PROPERTIES}")

    set_target_properties (${TARGET} PROPERTIES
                           POLYSQUARE_ACCELERATED ON
                           ${COTIRE_PROPERTIES})

    # Clear COTIRE_PREFIX_HEADER_IGNORE_PATH
    set_target_properties (${TARGET} PROPERTIES
                           COTIRE_PREFIX_HEADER_IGNORE_PATH
                           "")

    cotire (${TARGET})

    # Add dependencies to unity target
    if (NOT ACCELERATION_NO_UNITY_BUILD)

        psq_forward_options (ACCELERATION WIRE_DEPS_OPTIONS
                             MULTIVAR_ARGS DEPENDS)
        psq_wire_mirrored_build_target_dependencies (${TARGET}
                                                     unity
                                                     ${WIRE_DEPS_OPTIONS})

    endif (NOT ACCELERATION_NO_UNITY_BUILD)

endfunction (psq_accelerate_target)
