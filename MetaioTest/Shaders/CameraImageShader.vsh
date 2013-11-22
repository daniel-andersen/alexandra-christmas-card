attribute vec4 position;
attribute vec2 texCoords;

varying lowp vec2 texCoordsVarying;

uniform mat4 modelViewProjectionMatrix;

void main()
{
	texCoordsVarying = texCoords;

	gl_Position = modelViewProjectionMatrix * position;
}
