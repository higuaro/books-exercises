#include <iostream>
#include <string>
#include <chrono>

#include <boost/filesystem.hpp>

#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>

#include "glad/glad.h"
#include "../common/shader_program.hpp"
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

void init_logging() {
  // logging filtering only enabled for non DEBUG builds
#ifndef DEBUG
  logging::add_file_log("logs.log");
  logging::core::get()->set_filter(
      logging::trivial::severity >= logging::trivial::info
  );
#endif
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

  // Log hardware capabilities info
  int num_attributes;
  glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &num_attributes);
  BOOST_LOG_TRIVIAL(info) << "num vertex att supported: " << num_attributes;

  glViewport(0, 0, 800, 600);

  float vertices[] = {
      0.5f,  0.5f, 0.0f,  // top right
      0.5f, -0.5f, 0.0f,  // bottom right
      -0.5f, -0.5f, 0.0f, // bottom left
      -0.5f,  0.5f, 0.0f  // top left
  };
  uint32_t indices[] = {
      0, 1, 3, // first triangle
      1, 2, 3  // second triangle
  };

  uint32_t vao_handle;
  glGenVertexArrays(/* of VBAs to generate */ 1, &vao_handle);
  glBindVertexArray(vao_handle);

  uint32_t vbo_handle;
  glGenBuffers(/* num of VBOs to generate */ 1, &vbo_handle);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_handle);
  glBufferData(GL_ARRAY_BUFFER, sizeof vertices, vertices, GL_STATIC_DRAW);

  uint32_t ebo_handle;
  glGenBuffers(/* num of EBOs to generate */ 1, &ebo_handle);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo_handle);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof indices, indices, GL_STATIC_DRAW);

  glVertexAttribPointer(
      0, // vertex attribute to configure
      3, // size of the vertex attribute (vec3)
      GL_FLOAT, // attribute type (vec* in GLSL consists of floats)
      GL_FALSE, // if integer data should be normalized
      3 * sizeof(float), // stride
      nullptr // position data offset in the buffer
  );
  glEnableVertexAttribArray(/* attribute index = */ 0);
  glBindVertexArray(0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);

  shader_program shader("tut");
  if (auto res = shader.load(); res) {
    return abort_program(res.value());
  }

  // render loop
  while(!glfwWindowShouldClose(window)) {
    // input
    process_input(window);

    glClearColor(0.2f, 0.3f, 0.3f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(shader.program_handle());
    glBindVertexArray(vao_handle);

    using namespace std::chrono;
    auto sec = duration_cast<seconds>(system_clock::now().time_since_epoch());

    glPolygonMode(GL_FRONT_AND_BACK, (sec % 10) >= 5s ? GL_LINE : GL_FILL);

    glDrawElements( //
        GL_TRIANGLES, //
        6, // num vertex to draw
        GL_UNSIGNED_INT, // indices type
        nullptr // offset
    );

    // check and call events and swap buffers
    glfwSwapBuffers(window);
    glfwPollEvents();
  }

  glfwTerminate();
  return 0;
}

