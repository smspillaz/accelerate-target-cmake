# /CMakeLists.txt
#
# Main entry point for AccelerateTarget tests.
#
# See /LICENCE.md for Copyright information
include ("${CMAKE_CURRENT_LIST_DIR}/conanbuildinfo.cmake")
set (CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_LIST_DIR}"
     ${CONAN_CMAKE_MODULE_PATH}  # NOLINT:correctness/quotes
     ${CMAKE_MODULE_PATH})  # NOLINT:correctness/quotes

cmake_minimum_required (VERSION 2.8)

set (_CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}")

include ("cmake/cmake-module-common/Common" OPTIONAL)
include (AccelerateTarget)

macro (psq_export_cfg_int_dir_helper)
    set (OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/CfgIntDirValue.txt")
    set (WRITE_TO_OUTPUT_FILE_SCRIPT
         "${CMAKE_CURRENT_BINARY_DIR}/WriteCfgIntDir.cmake")
    set (WRITE_TO_OUTPUT_FILE_SCRIPT_CONTENTS
         "file (WRITE \"${OUTPUT_FILE}\" \"\${INTDIR}\")\n")
    file (WRITE ${WRITE_TO_OUTPUT_FILE_SCRIPT}
          "${WRITE_TO_OUTPUT_FILE_SCRIPT_CONTENTS}")
    add_custom_command (OUTPUT "${OUTPUT_FILE}"
                        COMMAND
                        "${CMAKE_COMMAND}"
                        -DINTDIR=${CMAKE_CFG_INTDIR}
                        -P
                        ${WRITE_TO_OUTPUT_FILE_SCRIPT})
    add_custom_target (write_cfg_int_dir ALL
                       SOURCES "${OUTPUT_FILE}")
endmacro ()

macro (psq_import_cfg_int_dir_helper)
    file (READ
          "${BINARY_DIR}/CfgIntDirValue.txt"
          CMAKE_CFG_INTDIR)  # NOLINT:unused/var_in_func
endmacro ()

# Verifies that passing NO_PRECOMPILED_HEADERS to psq_accelerate_target
# causes precompiled headers not to be generated.
function (psq_test_no_p_c_h_option)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        psq_accelerate_target ("${EXECUTABLE}" NO_PRECOMPILED_HEADERS)
        cmake_unit_assert_that ("${EXECUTABLE}_pch" not target_exists)
    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                               CONFIGURE COMMAND psq_configure)
endfunction ()

# Verifies that passing NO_UNITY_BUILD causes unity targets not to be generated.
function (psq_test_no_unity_build_option)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        psq_accelerate_target ("${EXECUTABLE}" NO_UNITY_BUILD)
        cmake_unit_assert_that ("${EXECUTABLE}_unity" not target_exists)
    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND psq_configure
                                           INVOKE_CONFIGURE OPTIONS
                                                            LANGUAGES
                                                            C
                                                            CXX)
endfunction ()

# Verifies that after calling psq_accelerate_target
# _pch targets are generated on that target
function (psq_test_p_c_h_targets_generated_after_accelerating_target)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        psq_accelerate_target ("${EXECUTABLE}")
        if (XCODE)
            cmake_unit_assert_that ("${EXECUTABLE}"
                                    item_has_property_with_value
                                    TARGET
                                    XCODE_ATTRIBUTE_GCC_PRECOMPILE_PREFIX_HEADER
                                    STRING
                                    EQUAL
                                    "YES")
        else ()
            cmake_unit_assert_that ("${EXECUTABLE}_pch" target_exists)
        endif ()
    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE OPTIONS
                                                            LANGUAGES
                                                            C
                                                            CXX
                                           CONFIGURE COMMAND psq_configure
                                           PRECONFIGURE OPTIONS
                                                        SKIP_GENERATOR_REGEX
                                                        "^Visual Studio.*$"
                                                        "NMake Makefiles")
endfunction ()

# Tests that the COTIRE_PREFIX_HEADER_IGNORE_PATH property is cleared
# on accelerated targets
function (psq_test_prefix_header_cleared_on_target)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        cmake_unit_assert_that ("${EXECUTABLE}"
                                item_has_property_with_value
                                TARGET
                                COTIRE_PREFIX_HEADER_IGNORE_PATH
                                STRING
                                EMPTY
                                EMPTY)
    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE OPTIONS
                                                            LANGUAGES
                                                            C
                                                            CXX
                                           CONFIGURE COMMAND psq_configure)
endfunction ()

# Places some headers in the source / build directories, but the header
# is a generated file.
function (psq_test_skip_generated_files_in_p_c_h_file)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (psq_configure)
        psq_export_cfg_int_dir_helper ()
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        cmake_unit_generate_source_file_during_build (TARGET NAME "Header.h"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    INCLUDES "Header.h"
                                                    FUNCTIONS main
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        include_directories ("${BINARY_DIR}")
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp"
                        "${BINARY_DIR}/Header.h")
        psq_accelerate_target ("${EXECUTABLE}")
    endfunction ()

    function (psq_verify)
        psq_import_cfg_int_dir_helper ()
        set (BINARY_OUTPUT_DIR
             "${BINARY_DIR}/${CMAKE_CFG_INTDIR}")
        set (PREFIX_HEADER_FILE
             "${BINARY_OUTPUT_DIR}/cotire/executable_CXX_prefix.hxx")

        # On Visual Studio, we have the opposite behavior
        if ("${CMAKE_GENERATOR}" MATCHES "^Visual.*$|^NMake.*$")
            cmake_unit_assert_that ("${BINARY_DIR}/Header.h"
                                    exists_as_file)
            cmake_unit_assert_that ("${PREFIX_HEADER_FILE}"
                                    file_contents
                                    any_line
                                    matches_regex
                                    "^.*Header.h.*$")
        else ()
            cmake_unit_assert_that ("${PREFIX_HEADER_FILE}"
                                    not
                                    file_contents
                                    any_line
                                    matches_regex
                                    "^.*Header.h.*$")
        endif ()
    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                               CONFIGURE COMMAND psq_configure
                               VERIFY COMMAND psq_verify)
endfunction ()

# Verifies the generated _unity targets depend on the _unity version
# of other targets where those exist.
function (psq_test_unity_build_targets_depend_on_unity_dependencies)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (LIBRARY library)
        cmake_unit_create_simple_library ("${LIBRARY}" SHARED
                                          GENERATING_FILE
                                          "${_CURRENT_LIST_FILE}")
        psq_accelerate_target (${LIBRARY})
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        target_link_libraries ("${EXECUTABLE}" "${LIBRARY}")
        psq_accelerate_target ("${EXECUTABLE}")
        set (EXECUTABLE_UNITY "${EXECUTABLE}_unity")
        set (LIBRARY_UNITY ${LIBRARY}_unity)
        cmake_unit_assert_that (${EXECUTABLE_UNITY} is_linked_to
                                ${LIBRARY_UNITY})
    endfunction ()

    function (psq_verify)
        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents any_line matches_regex
                                "^.*library_unity.*$")
    endfunction ()
    cmake_unit_configure_test (CONFIGURE COMMAND psq_configure
                               VERIFY COMMAND psq_verify
                               INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                               INVOKE_BUILD OPTIONS TARGET executable_unity)
endfunction ()

# Verifies that after calling psq_accelerate_target
# _unity targets are generated for that target
function (psq_test_unity_build_targets_generated_after_accelerating_target)
    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        psq_accelerate_target ("${EXECUTABLE}")
        cmake_unit_assert_that ("${EXECUTABLE}_unity" target_exists)
    endfunction ()
    cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                               CONFIGURE COMMAND psq_configure)
endfunction ()

# Verifies that after calling psq_accelerate_target
# _unity targets are generated for that target
function (psq_test_unity_build_targets_generated_after_cotire_bootstrap)
    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        psq_accelerate_target ("${EXECUTABLE}")
        cmake_unit_assert_that ("${EXECUTABLE}_unity" target_exists)
    endfunction ()
    cmake_unit_configure_config_only_test (CONFIGURE COMMAND psq_configure
                                           INVOKE_CONFIGURE OPTIONS
                                                            LANGUAGES
                                                            C
                                                            CXX)
endfunction ()

# Verifies the generated _unity target inherits all non-library
# dependencies
function (psq_test_unity_build_targets_inherit_dependencies)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (CUSTOM_COMMAND_OUTPUT
             "${BINARY_DIR}/custom_command_output")
        file (REMOVE ${CUSTOM_COMMAND_OUTPUT})
        add_custom_command (OUTPUT ${CUSTOM_COMMAND_OUTPUT} COMMAND
                            "${CMAKE_COMMAND}"
                            -E
                            touch
                            ${CUSTOM_COMMAND_OUTPUT})
        set (CUSTOM_TARGET_NAME custom_target)
        add_custom_target (${CUSTOM_TARGET_NAME} SOURCES
                           ${CUSTOM_COMMAND_OUTPUT})
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        add_dependencies ("${EXECUTABLE}" ${CUSTOM_TARGET_NAME})
        psq_accelerate_target ("${EXECUTABLE}" DEPENDS ${CUSTOM_TARGET_NAME})
    endfunction ()

    function (psq_verify)
        set (CUSTOM_COMMAND_OUTPUT
             "${BINARY_DIR}/custom_command_output")
        cmake_unit_assert_that (${CUSTOM_COMMAND_OUTPUT} exists_as_file)
    endfunction ()
    cmake_unit_configure_test (CONFIGURE COMMAND psq_configure
                               VERIFY COMMAND psq_verify
                               INVOKE_BUILD OPTIONS TARGET all_unity
                               INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX)
endfunction ()

# Verifies the generated _unity target inherits all external target link
# libraries, that don't have corresponding unity targets.
function (psq_test_unity_build_targets_inherit_target_link_libraries)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (psq_configure)
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        set (LIBRARY library)
        cmake_unit_create_simple_library ("${LIBRARY}" SHARED
                                          GENERATING_FILE
                                          "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        cmake_unit_create_simple_executable ("${EXECUTABLE}"
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        target_link_libraries ("${EXECUTABLE}" "${LIBRARY}")
        psq_accelerate_target ("${EXECUTABLE}")
        set (EXECUTABLE_UNITY "${EXECUTABLE}_unity")
        cmake_unit_assert_that (${EXECUTABLE_UNITY} is_linked_to ${LIBRARY})
    endfunction ()

    function (psq_verify)
        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*executable_unity.*library.*$")
    endfunction ()
    cmake_unit_configure_test (CONFIGURE COMMAND psq_configure
                               VERIFY COMMAND psq_verify
                               INVOKE_BUILD OPTIONS TARGET all_unity
                               INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX)
endfunction ()

# Places some headers in the source / build directories.
function (psq_test_use_files_in_build_directory_in_p_c_h_file)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (psq_configure)
        psq_export_cfg_int_dir_helper ()
        set (COTIRE_MINIMUM_NUMBER_OF_TARGET_SOURCES 1 CACHE BOOL "" FORCE)
        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    INCLUDES "Header.h"
                                                    FUNCTIONS main
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        include_directories ("${BINARY_DIR}")
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp"
                        "${SOURCE_DIR}/Header.h")
        psq_accelerate_target ("${EXECUTABLE}")

        # Add write_cfg_int_dir to all_unity so that it gets run
        if ("${CMAKE_GENERATOR}" MATCHES "Unix Makefiles|Ninja")
            add_dependencies (all_pch write_cfg_int_dir)
        endif ()
    endfunction ()

    function (psq_verify)
        psq_import_cfg_int_dir_helper ()
        set (BINARY_OUTPUT_DIR "${BINARY_DIR}/${CMAKE_CFG_INTDIR}")
        if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC")
            set (PREFIX_HEADER_FILE
                 "${BINARY_OUTPUT_DIR}/cotire/executable_CXX_prefix.hxx")
        else ()
            set (PREFIX_HEADER_FILE
                 "${BINARY_OUTPUT_DIR}/cotire/executable_CXX_prefix.cxx")
        endif ()
        cmake_unit_assert_that ("${PREFIX_HEADER_FILE}" file_contents any_line
                                matches_regex
                                "^.*Header.h.*$")
    endfunction ()

    if ("${CMAKE_GENERATOR}" MATCHES "Unix Makefiles|Ninja")
        cmake_unit_configure_test (CONFIGURE COMMAND psq_configure
                                   VERIFY COMMAND psq_verify
                                   INVOKE_BUILD OPTIONS TARGET all_pch
                                   INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX)
    else ()
        cmake_unit_configure_test (CONFIGURE COMMAND psq_configure
                                   VERIFY COMMAND psq_verify
                                   INVOKE_BUILD OPTIONS
                                   INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX)
    endif ()
endfunction ()

set (CMAKE_FILES
     "${CMAKE_CURRENT_LIST_DIR}/AccelerateTarget.cmake"
     "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt")
set (MARKDOWN_FILES
     "${CMAKE_CURRENT_LIST_DIR}/LICENCE.md"
     "${CMAKE_CURRENT_LIST_DIR}/README.md")

if (COMMAND cmake_module_add_common_targets)

    cmake_module_add_common_targets (NAMESPACE "psq"
                                     CMAKE_FILES ${CMAKE_FILES}
                                     DOCUMENTATION_FILES ${MARKDOWN_FILES})

endif ()
