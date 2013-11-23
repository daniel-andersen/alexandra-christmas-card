varying lowp vec2 texCoordsVarying;
uniform sampler2D texture;
uniform lowp float alpha;

void main()
{
    gl_FragColor = texture2D(texture, texCoordsVarying);
    gl_FragColor.rgb = alpha * gl_FragColor.rgb;
}
