varying lowp vec2 texCoordsVarying;
uniform sampler2D texture;

void main()
{
    gl_FragColor = texture2D(texture, texCoordsVarying);
}
