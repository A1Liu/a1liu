#version 300 es

precision highp float;

in vec4 o_color;

out vec4 out_color; // you can pick any name

// This was a lot simpler when I could use integer division. :(
void main() {
  out_color = o_color;
}
