#pragma once

#include <boost/filesystem.hpp>

#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/utility/setup/file.hpp>

#include <glad/glad.h>

#include <cstdint>
#include <string>

namespace fs = boost::filesystem;

class shader {
public:
  uint32_t id;

  shader(const std::string& shader_id) {
  }

  ~shader() {
  }

private:

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
};