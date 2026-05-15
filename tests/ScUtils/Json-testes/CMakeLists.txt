sc_add_project(Json-testes "Tests for the Sc JSON C++ SDK" ScUtils)

add_executable(${PROJECT_NAME} "main.cpp")

target_link_libraries(${PROJECT_NAME} ${PROJECT_LIBS})

if(MSVC)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        VS_DEBUGGER_ENVIRONMENT "PATH=$<TARGET_FILE_DIR:ScUtils>;%PATH%"
    )
endif()