#[[
	Macro: sc_add_project
	Description:
		Initializes a standard project, automatically resolves its version, defines 
	a SHARED library target, and configures common properties including output name, 
	compile definitions, target include directories, dependency linking, and installation settings.
	
	Arguments:
		- name        : Name of the project and the generated target.
		- description : Brief description of the project.
		- [ARGN]      : Optional extra libraries or targets to link against.
]]
macro(sc_add_project name inc_dir description)
	set(PROJECT_LIBS "${ARGN}")
	set(SC_PROJECT_DIR ${CMAKE_CURRENT_LIST_DIR})
	set(SC_INCLUDE_DIR "${inc_dir}")
	
	# Specify the project suffix under Debug configuration
	if (NOT DEFINED CMAKE_DEBUG_POSTFIX)
		set(CMAKE_DEBUG_POSTFIX "d")
	endif()

	# Enforce rigid standard policies locally inside the function scope
	# CMP0028: Double colons (::) in target names strictly represent ALIAS or IMPORTED targets.
	# CMP0048: The project() command natively manages and updates VERSION variables.
	# CMP0054: The if() command will not implicitly dereference quoted arguments or keywords.
	# CMP0056: The try_compile() source-file signature correctly honors CMAKE_EXE_LINKER_FLAGS.
	foreach(policy_id CMP0028 CMP0048 CMP0054 CMP0056)
        if(POLICY ${policy_id})
            cmake_policy(SET ${policy_id} NEW)
        endif()
    endforeach()
	
	# Resolve versioning properties
	sc_obtain_project_version()

	project(${name} VERSION "${PROJECT_VERSION}" LANGUAGES CXX C)
	
	# Collect source and header files
	include(ide)

	# Automatically define library targets
	if(SC_BUILD_SHARED_LIBS)
		add_library(${PROJECT_NAME} SHARED ${SC_SOURCES_ALL} ${SC_HEADERS_ALL})
	else()
		add_library(${PROJECT_NAME} STATIC ${SC_SOURCES_ALL} ${SC_HEADERS_ALL})
	endif()
	
	# Set the actual output file name
	string(TOLOWER ${name} SC_OUTPUT_NAME)
	set_target_properties(${PROJECT_NAME} PROPERTIES
		OUTPUT_NAME "${SC_OUTPUT_NAME}"
		DESCRIPTION "${PROJECT_DESCRIPTION}"
	)
	
	# Inject clean build/install interface paths safely into the target property
	target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    )
	
	# Link dependencies strictly as PRIVATE to hide cjson/spdlog implementation details
	if(PROJECT_LIBS)
		foreach(lib IN LISTS PROJECT_LIBS)
			target_link_libraries(${PROJECT_NAME} PRIVATE $<BUILD_INTERFACE:${lib}>)
		endforeach()
	endif()

	sc_setup_install("${SC_INCLUDE_DIR}")

	sc_do_packaging()
endmacro()


#[[
	Macro: sc_obtain_project_version
	Description:
		Retrieves the project version string. It prioritizes the latest Git tag 
	via 'git describe'. If Git is unavailable or fails, it attempts to read 
	from a local 'VERSION' file. If both fail, it defaults to '1.0.0'.
	
	Arguments:
		None.
]]
macro(sc_obtain_project_version)
	if (GIT_FOUND)
		execute_process(
			COMMAND ${GIT_EXECUTABLE} --git-dir=${CMAKE_CURRENT_SOURCE_DIR}/.git describe --abbrev=0 --tags
			OUTPUT_VARIABLE VERSION_STRING
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET
        )

		execute_process(
			COMMAND ${GIT_EXECUTABLE} --git-dir=${CMAKE_CURRENT_SOURCE_DIR}/.git rev-parse HEAD
			RESULT_VARIABLE git_result
			OUTPUT_VARIABLE GIT_HASH
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET
        )

		if (NOT git_result)
			message(STATUS "Building git hash: ${GIT_HASH}")
        endif()
	endif()

	if (NOT VERSION_STRING)
		set(VERSION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
		if(EXISTS "${VERSION_FILE}")
			file(READ "${VERSION_FILE}" VERSION_STRING)
		else()
			set(VERSION_STRING "1.0.0")
		endif()
	endif()

	set(PROJECT_VERSION "${VERSION_STRING}")
endmacro()