#version 330 core
out vec4 fragColor;

uniform vec4 our_color;

void main() {
  fragColor = our_color;
}