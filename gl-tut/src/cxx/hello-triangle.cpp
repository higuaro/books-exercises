#include <iostream>
#include <string>
#include <sstream>
#include <optional>

#include <boost/filesystem.hpp>

#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/utility/setup/file.hpp>

#include "glad/glad.h"
#include <GLFW/glfw3.h>

namespace fs = boost::filesystem;
namespace logging = boost::log;

int abort_program(const std::string& msg = "") {
  if (!msg.empty()) {
    BOOST_LOG_TRIVIAL(fatal) << msg;
  }
  BOOST_LOG_TRIVIAL(fatal) << "Terminating program now";
  glfwTerminate();
  exit(1);
}

void process_input(GLFWwindow* window) {
  if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
    glfwSetWindowShouldClose(window, /* value= */ true);
  }
}

void error_callback(int error, const char *msg) {
  std::ostringstream oss;
  oss << "error number: " << error << ", msg: " << msg;
  abort_program(oss.str());
}

void framebuffer_size_callback(GLFWwindow* wnd, int width, int height) {
  glViewport(0, 0, width, height);
}

std::string load_shader_content(const std::string& file_name) {
  fs::path file_path{fs::current_path() / "res" / "glsl" / file_name};
  if (!fs::exists(file_path)) {
    abort_program("Couldn't load shader file: " + file_path.string());
  }
  fs::ifstream shader_file(file_path);
  return { //
    std::istreambuf_iterator<char>(shader_file), //
    std::istreambuf_iterator<char>() //
  };
}

void init_logging() {
  // logging filtering only enabled for non DEBUG builds
#ifndef DEBUG
  logging::add_file_log("logs.log");
  logging::core::get()->set_filter(
      logging::trivial::severity >= logging::trivial::info
  );
#endif
}

std::optional<std::string> check_shader_status( //
    const uint32_t shader_id, //
    const GLenum status_type //
) {
  int success = 0;
  const size_t buffer_size = 512;
  char log[buffer_size];
  std::memset(log, 0, sizeof log);
  switch (status_type) {
    case GL_COMPILE_STATUS:
      glGetShaderiv(shader_id, GL_COMPILE_STATUS, &success);
      break;
    case GL_LINK_STATUS:
      glGetProgramiv(shader_id, GL_LINK_STATUS, &success);
      break;
    default:
      abort_program("Unexpected status_type = " + std::to_string(status_type));
  }
  if (!success) {
    glGetShaderInfoLog(shader_id, buffer_size, /* length = */ nullptr, log);
    return { std::string(log) };
  }
  return std::nullopt;
}

std::optional<std::string> check_shader_compilation(const uint32_t shader_id) {
  return check_shader_status(shader_id, GL_COMPILE_STATUS);
}

std::optional<std::string> check_shader_linking(const uint32_t shader_id) {
  return check_shader_status(shader_id, GL_LINK_STATUS);
}

uint32_t load_shader() {
  const std::string vertex_shader_src(load_shader_content("tut.vert"));
  BOOST_LOG_TRIVIAL(trace) << "vertex shader: " << vertex_shader_src;
  const char* const_vertex_shader_src = vertex_shader_src.c_str();

  uint32_t vertex_shader_handler = glCreateShader(GL_VERTEX_SHADER);
  glShaderSource( //
      vertex_shader_handler, // shader id
      1, // count
      &const_vertex_shader_src, //
      nullptr // length
  );
  glCompileShader(vertex_shader_handler);
  if (auto res = check_shader_compilation(vertex_shader_handler); res) {
    return abort_program("Error compiling vert shader: " + res.value());
  }

  const std::string fragment_shader_src(load_shader_content("tut.frag"));
  BOOST_LOG_TRIVIAL(trace) << "fragment shader: " << fragment_shader_src;
  const char* const_fragment_shader_src = fragment_shader_src.c_str();

  uint32_t fragment_shader_handler = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(
      fragment_shader_handler, //
      1, // count
      &const_fragment_shader_src, //
      nullptr // length
  );
  glCompileShader(fragment_shader_handler);
  if (auto res = check_shader_compilation(fragment_shader_handler); res) {
    return abort_program("Error compiling frag shader: " + res.value());
  }

  uint32_t shader_program_handler = glCreateProgram();
  glAttachShader(shader_program_handler, vertex_shader_handler);
  glAttachShader(shader_program_handler, fragment_shader_handler);
  glLinkProgram(shader_program_handler);
  if (auto res = check_shader_linking(shader_program_handler); res) {
    return abort_program("Error linking shader: " + res.value());
  }

  glDeleteShader(vertex_shader_handler);
  glDeleteShader(fragment_shader_handler);

  return shader_program_handler;
}

GLFWwindow* create_ogl_window() {
  glfwSetErrorCallback(error_callback);

  glfwInit();
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

  auto* window = glfwCreateWindow( //
      800, // width
      600, // height
      "gl-tut", // title
      nullptr, // monitor info
      nullptr // share
  );

  if (window == nullptr) {
    abort_program("Failed to create GLFW window");
    return nullptr;
  }
  glfwMakeContextCurrent(window);

  if (!gladLoadGLLoader((GLADloadproc) glfwGetProcAddress)) {
    abort_program("Failed to initialize GLAD");
    return nullptr;
  }

  glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
  return window;
}


int main() {
  init_logging();
  BOOST_LOG_TRIVIAL(debug) << "Starting. CWD: " << fs::current_path();

  auto* window = create_ogl_window();
  glViewport(0, 0, 800, 600);

  float vertices[] = {
    -0.5f, -0.5f, 0.0f,
     0.5f, -0.5f, 0.0f,
     0.0f,  0.5f, 0.0f
  };

  uint32_t vao_handle;
  glGenVertexArrays(/* of VBAs to generate */ 1, &vao_handle);
  glBindVertexArray(vao_handle);

  uint32_t vbo_handle;
  glGenBuffers(/* num of VBOs to generate */ 1, &vbo_handle);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_handle);
  glBufferData(GL_ARRAY_BUFFER, sizeof vertices, vertices, GL_STATIC_DRAW);

  glVertexAttribPointer(
      0, // vertex attribute to configure
      3, // size of the vertex attribute (vec3)
      GL_FLOAT, // attribute type (vec* in GLSL consists of floats)
      GL_FALSE, // if integer data should be normalized
      3 * sizeof(float), // stride
      static_cast<void*>(nullptr) // position data offset in the buffer
  );
  glEnableVertexAttribArray(/* attribute index = */ 0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);

  auto shader_program_handle = load_shader();

  // render loop
  while(!glfwWindowShouldClose(window)) {
    // input
    process_input(window);

    glClearColor(0.2f, 0.3f, 0.3f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(shader_program_handle);
    glBindVertexArray(vao_handle);
    glDrawArrays(GL_TRIANGLES, /* start index = */ 0, /* vertex count = */ 3);

    // check and call events and swap buffers
    glfwSwapBuffers(window);
    glfwPollEvents();
  }

  glfwTerminate();
  return 0;
}

