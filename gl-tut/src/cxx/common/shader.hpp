#pragma once

#include <boost/filesystem.hpp>

#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/utility/setup/file.hpp>

#include "glad/glad.h"

#include <cstdint>
#include <string>
#include <utility>
#include <variant>
#include <optional>

namespace fs = boost::filesystem;

class shader {
public:
  uint32_t shader_program_handler;
  const std::string shader_id;

  explicit shader(std::string shader_id)
      : shader_program_handler(-1), shader_id(std::move(shader_id)) {
  }

  ~shader() {
    if (shader_program_handler != -1) {
      glDeleteProgram(shader_program_handler);
    }
  }

private:
  enum either_type : std::size_t { src = 0, err = 1 };
  typedef std::variant<std::string, std::string> source_or_error;

  static inline source_or_error make_error(const std::string& msg) {
    return source_or_error{std::in_place_index<either_type::err>, msg};
  }

  static inline source_or_error make_source(const std::string& source) {
    return source_or_error{std::in_place_index<either_type::src>, source};
  }

  static inline std::string get_error(const source_or_error& either) {
    return std::get<either_type::err>(either);
  }

  static inline std::string get_source(const source_or_error& either) {
    return std::get<either_type::src>(either);
  }

  static inline bool is_error(const source_or_error& either) {
    return either.index() == either_type::err;
  }

  static inline std::string read_file(std::ifstream& file) {
    return {
      std::istreambuf_iterator<char>(file), //
      std::istreambuf_iterator<char>() //
    };
  }

  static source_or_error load_shader_content(const std::string& file_name) {
    fs::path file_path{fs::current_path() / "res" / "glsl" / file_name};
    if (!fs::exists(file_path)) {
      return make_error("Couldn't load shader file: " + file_path.string());
    }

    fs::ifstream shader_file(file_path);

    return make_source(read_file(shader_file));
  }

  static std::optional<std::string> check_shader_status( //
      const uint32_t shader_handle, //
      const GLenum status_type //
  ) {
    int success = 0;
    const size_t buffer_size = 512;
    char log[buffer_size];
    std::memset(log, 0, sizeof log);
    switch (status_type) {
      case GL_COMPILE_STATUS:
        glGetShaderiv(shader_handle, GL_COMPILE_STATUS, &success);
        break;
      case GL_LINK_STATUS:
        glGetProgramiv(shader_handle, GL_LINK_STATUS, &success);
        break;
      default:
        return std::optional{ //
          "Unexpected status_type = " + std::to_string(status_type) //
        };
    }
    if (!success) {
      glGetShaderInfoLog(shader_handle, buffer_size, nullptr, log);
      return { std::string(log) };
    }
    return std::nullopt;
  }

  static inline std::optional<std::string> check_shader_compilation( //
      const uint32_t shader_handle //
  ) {
    return check_shader_status(shader_handle, GL_COMPILE_STATUS);
  }

  static inline std::optional<std::string> check_shader_linking( //
      const uint32_t shader_handle //
  ) {
    return check_shader_status(shader_handle, GL_LINK_STATUS);
  }

public:

  [[nodiscard]] inline uint32_t handle() const {
    return shader_program_handler;
  }

  std::optional<std::string> load() {
    auto load_res = load_shader_content(shader_id + ".vert");
    if (is_error(load_res)) {
      return std::make_optional(get_error(load_res));
    }

    const auto vertex_shader_src = get_source(load_res);
    BOOST_LOG_TRIVIAL(trace) << "vertex shader [" << shader_id << "]: "
        << vertex_shader_src;
    const auto* const_vertex_shader_src = vertex_shader_src.c_str();

    auto vertex_shader_handler = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource( //
        vertex_shader_handler, // shader id
        1, // count
        &const_vertex_shader_src, //
        nullptr // length
    );
    glCompileShader(vertex_shader_handler);

    if (auto res = check_shader_compilation(vertex_shader_handler); res) {
      return std::make_optional( //
          "Error compiling vertex shader [" + shader_id + "]: " + res.value()
      );
    }

    load_res = load_shader_content(shader_id + ".frag");
    if (is_error(load_res)) {
      return std::make_optional(get_error(load_res));
    }

    const auto fragment_shader_src = get_source(load_res);
    BOOST_LOG_TRIVIAL(trace) << "fragment shader [" << shader_id << "]: "
        << fragment_shader_src;
    const auto* const_fragment_shader_src = fragment_shader_src.c_str();

    auto fragment_shader_handler = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(
        fragment_shader_handler, //
        1, // count
        &const_fragment_shader_src, //
        nullptr // length
    );
    glCompileShader(fragment_shader_handler);
    if (auto res = check_shader_compilation(fragment_shader_handler); res) {
      return make_optional( //
          "Error compiling fragment shader [" + shader_id + "]: " + res.value()
      );
    }

    shader_program_handler = glCreateProgram();

    glAttachShader(shader_program_handler, vertex_shader_handler);
    glAttachShader(shader_program_handler, fragment_shader_handler);
    glLinkProgram(shader_program_handler);

    if (auto res = check_shader_linking(shader_program_handler); res) {
      return make_optional( //
          "Error linking shader [" + shader_id + "]: " + res.value() //
      );
    }

    glDeleteShader(vertex_shader_handler);
    glDeleteShader(fragment_shader_handler);

    // No error
    return std::nullopt;
  }
};