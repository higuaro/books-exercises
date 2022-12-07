cmake_minimum_required(VERSION 3.23)
project(gl_tut)

set(CMAKE_CXX_STANDARD 20)

# The `pkg_check_modules` function is created with this call
# 'PkgConfig' makes the pkg-config command line tool available from CMake
find_package(PkgConfig REQUIRED)

# Equivalent to checking that the command 'pkg-config glfw3' succeeds
pkg_check_modules(GLFW REQUIRED IMPORTED_TARGET "glfw3")

message(STATUS "GLFW_INCLUDE_DIRS at ${GLFW_INCLUDE_DIRS} FOUND")
message(STATUS "GLFW_LIBRARIES at ${GLFW_LIBRARIES} FOUND")

# Boost
find_package(Boost COMPONENTS log filesystem REQUIRED)

add_subdirectory(lib/glad/)

# Adds the DEBUG definition for the DEBUG build
add_compile_options("$<$<CONFIG:DEBUG>:-DDEBUG>")

foreach(program hello-triangle ebo shaders-uniform shaders-more-atts)
  add_executable(${program} src/cxx/ch1/${program}.cpp)

  target_include_directories(${program} PUBLIC ${GLFW_INCLUDE_DIRS} ${CMAKE_CURRENT_SOURCE_DIR}/include/)

  target_link_libraries(${program} Boost::filesystem Boost::log PkgConfig::GLFW glad)

  # Copy the content of the 'res' folder into the executable build path
  add_custom_command(TARGET ${program} POST_BUILD
          COMMAND ${CMAKE_COMMAND} -E copy_directory
          ${CMAKE_SOURCE_DIR}/res $<TARGET_FILE_DIR:${program}>/res)
endforeach()


