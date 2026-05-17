# ---------------------------------------------------------------------------------------
# IDE Support
# ---------------------------------------------------------------------------------------
# Collect and filter files
function(sc_collect_filter output_var dir file_exts filter_regx)
	set(files "")
	foreach(ext ${file_exts})
		file(GLOB temp_files ${dir}/*.${ext})
		list(APPEND files ${temp_files})
	endforeach()

	if (${filter_regx})
		list(FILTER files EXCLUDE REGEX ${${filter_regx}})
	endif()

	set(${output_var} ${files} PARENT_SCOPE)
endfunction()

# Collect files
function(sc_collect_files output_var group_name dir file_exts filter_regx)
	set(last_name "")
	file(GLOB subdirs LIST_DIRECTORIES true "${dir}/*")
	foreach(subdir ${subdirs})
		if(NOT IS_DIRECTORY "${subdir}")
            continue()
        endif()

		sc_collect_filter(temp_files "${subdir}" "${${file_exts}}" "${filter_regx}")
		list(APPEND files ${temp_files})
		if(MSVC)
			get_filename_component(last_name ${subdir} NAME)
			source_group(${group_name}/${last_name} FILES ${temp_files})
		endif()
	endforeach()
	
	sc_collect_filter(temp_files "${dir}" "${${file_exts}}" "${filter_regx}")
	list(APPEND files ${temp_files})
	if(MSVC)
		source_group(${group_name} FILES ${temp_files})
	endif()
	
	set(${output_var} ${files} PARENT_SCOPE)
endfunction()

# Automatically convert the file extension list into regular expression grouping format
function(sc_make_ext_regex output_reg_var ext_var)
    set(exts "${${ext_var}}")
    string(REPLACE ";" "|" ext_regex "${exts}")
    set(ext_regex "(${ext_regex})")

    if(WIN32)
        set(filter_reg ".*_(linux|unix)\\.${ext_regex}$")
    else()
        set(filter_reg ".*_win\\.${ext_regex}$")
    endif()

    set(${output_reg_var} "${filter_reg}" PARENT_SCOPE)
endfunction()

# ---------------------------------------------------------------------------------------
# IDE Include Support
# ---------------------------------------------------------------------------------------
# Define suported file extensions
set(SC_HEADER_EXTENSIONS "h" "hpp")

# Specify the directory where the header file is located
set(SC_HEADERS_DIR "${SC_PROJECT_DIR}/include/${SC_INCLUDE_DIR}")

# Collect header files
sc_collect_files(SC_HEADERS_ALL "Header Files" "${SC_HEADERS_DIR}" SC_HEADER_EXTENSIONS "")

# ---------------------------------------------------------------------------------------
# IDE Source Support
# ---------------------------------------------------------------------------------------
# Define suported file extensions
set(SC_SOURCE_EXTENSIONS "c" "cpp")

# Specify the directory where the source file is located
set(SC_SOURCES_DIR "${SC_PROJECT_DIR}/src")

# Remove the file suffixes according to the system preset
sc_make_ext_regex(SC_SOURCE_FILTER_REG SC_SOURCE_EXTENSIONS)

# Collect source files
sc_collect_files(SC_SOURCES_ALL "Source Files" "${SC_SOURCES_DIR}" SC_SOURCE_EXTENSIONS SC_SOURCE_FILTER_REG)