varying lowp vec2 texCoordsVarying;
uniform sampler2D texture;
uniform lowp float alpha;

void main()
{
    gl_FragColor = texture2D(texture, texCoordsVarying);
    if (gl_FragColor.a < 0.1) {
        discard;
    } else {
        gl_FragColor.a = alpha * gl_FragColor.a;
    }
}
