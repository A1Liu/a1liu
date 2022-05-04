#version 300 es

precision highp float;

out vec4 out_color; // you can pick any name

// This was a lot simpler when I could use integer division. :(
void main() {
  out_color = vec4(0.5, 0.5,0.5, 1.0);
}
