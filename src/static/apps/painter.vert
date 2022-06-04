#version 300 es

in vec4 pos;
in vec4 color;

out vec4 o_color;

void main() {
  gl_Position = pos;
  o_color = color;
}
