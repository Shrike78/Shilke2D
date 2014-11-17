uniform mat4 transform;
uniform vec4 ucolor;

attribute vec4 position;
attribute vec4 color;

varying LOWP vec4 colorVarying;

void main () {
    gl_Position = position * transform;
    colorVarying = color * ucolor;
}