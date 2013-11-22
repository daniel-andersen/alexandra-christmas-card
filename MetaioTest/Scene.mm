#import <GLKit/GLKit.h>

#import "Scene.h"
#import "Gloomies.h"
#import "Constants.h"

#define BUFFER_OFFSET(i) ((uint8_t *)NULL + (i))

extern metaio::IMetaioSDKIOS *m_pMetaioSDK;

#define SNOWFLAKES_COUNT 1024

const float snowflakesMaxXZ = 500.0f;
const float snowflakesMaxY = 500.0f;

const float objectScaleX = 1.5f;
const float objectScaleY = 1.5f;

const float treeScaleX = 3.0f;
const float treeScaleY = 3.0f;

const float snowflakeScaleX = 0.035f;
const float snowflakeScaleY = 0.035f;

const float gloomieScaleX = 0.3f;
const float gloomieScaleY = 0.3f;

const Vertex gObjectVertexData[] = {
	{.position = { objectScaleX,                0.0f, -1.0f}, .texCoord = {1.0f, 0.0f}},
	{.position = {-objectScaleX,                0.0f, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = { objectScaleX, objectScaleY * 2.0f, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = { objectScaleX, objectScaleY * 2.0f, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = {-objectScaleX,                0.0f, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = {-objectScaleX, objectScaleY * 2.0f, -1.0f}, .texCoord = {0.0f, 1.0f}},
};

const Vertex gTreeVertexData[] = {
	{.position = { treeScaleX,              0.0f, -1.0f}, .texCoord = {1.0f, 0.0f}},
	{.position = {-treeScaleX,              0.0f, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = { treeScaleX, treeScaleY * 2.0f, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = { treeScaleX, treeScaleY * 2.0f, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = {-treeScaleX,              0.0f, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = {-treeScaleX, treeScaleY * 2.0f, -1.0f}, .texCoord = {0.0f, 1.0f}},
};

const Vertex gSnowflakeVertexData[] = {
	{.position = { snowflakeScaleX, -snowflakeScaleY, -1.0f}, .texCoord = {1.0f, 0.0f}},
	{.position = {-snowflakeScaleX, -snowflakeScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = { snowflakeScaleX,  snowflakeScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = { snowflakeScaleX,  snowflakeScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = {-snowflakeScaleX, -snowflakeScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = {-snowflakeScaleX,  snowflakeScaleY, -1.0f}, .texCoord = {0.0f, 1.0f}},
};

const Vertex gGloomieVertexData[] = {
	{.position = { gloomieScaleX, -gloomieScaleY, -1.0f}, .texCoord = {1.0f, 0.0f}},
	{.position = {-gloomieScaleX, -gloomieScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = { gloomieScaleX,  gloomieScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = { gloomieScaleX,  gloomieScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = {-gloomieScaleX, -gloomieScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = {-gloomieScaleX,  gloomieScaleY, -1.0f}, .texCoord = {0.0f, 1.0f}},
};

// Shader input attribute index
enum
{
	ATTRIB_VERTEX,
	ATTRIB_TEXCOORDS,
	NUM_ATTRIBUTES
};

// Uniform index
enum
{
	UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_ALPHA,
	NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];

typedef struct {
    GLKVector3 position;
    GLKVector3 velocity;
    float animation;
} Snowflake;

@interface Scene () {
    Gloomies *gloomies;
}

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation Scene {
	GLuint	m_shaderProgram;

	GLuint	m_objectVertexArray;
	GLuint	m_objectVertexBuffer;

	GLuint	m_treeVertexArray;
	GLuint	m_treeVertexBuffer;

	GLuint	m_snowflakeVertexArray;
	GLuint	m_snowflakeVertexBuffer;

	GLuint	m_gloomieVertexArray;
	GLuint	m_gloomieVertexBuffer;

    GLKTextureInfo *objectTexture[OBJECT_COUNT];
    GLKTextureInfo *treeTexture;
    GLKTextureInfo *snowflakeTexture;
    GLKTextureInfo *gloomieTexture;

    GLuint textureSampler;
    GLuint textureAlpha;
    
    GLKMatrix4 gloomiesModelViewMatrix;
    bool gloomiesIsTrackingMatrix;
    
    Snowflake snowflakes[SNOWFLAKES_COUNT];
}

- (id)init {
	if (self = [super init]) {
		[self loadShaders];

        for (int i = 0; i < SNOWFLAKES_COUNT; i++) {
            [self resetSnowflake:i random:YES];
        }
        
        // Snowman
		glGenVertexArraysOES(1, &m_objectVertexArray);
		glBindVertexArrayOES(m_objectVertexArray);

		glGenBuffers(1, &m_objectVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, m_objectVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(gObjectVertexData), gObjectVertexData, GL_STATIC_DRAW);

		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));

        glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
		glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));

        // Tree
		glGenVertexArraysOES(1, &m_treeVertexArray);
		glBindVertexArrayOES(m_treeVertexArray);
        
		glGenBuffers(1, &m_treeVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, m_treeVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(gTreeVertexData), gTreeVertexData, GL_STATIC_DRAW);
        
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
		glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));

        // Snowflake
		glGenVertexArraysOES(1, &m_snowflakeVertexArray);
		glBindVertexArrayOES(m_snowflakeVertexArray);
        
		glGenBuffers(1, &m_snowflakeVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, m_snowflakeVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(gSnowflakeVertexData), gSnowflakeVertexData, GL_STATIC_DRAW);
        
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
		glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));

        // Gloomie
		glGenVertexArraysOES(1, &m_gloomieVertexArray);
		glBindVertexArrayOES(m_gloomieVertexArray);
        
		glGenBuffers(1, &m_gloomieVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, m_gloomieVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(gGloomieVertexData), gGloomieVertexData, GL_STATIC_DRAW);
        
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
		glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));

        // Textures
        glBindVertexArrayOES(0);
        
        textureSampler = glGetUniformLocation(m_shaderProgram, "texture");
        textureAlpha = glGetUniformLocation(m_shaderProgram, "alpha");

        objectTexture[0] = [self setupTexture:@"Images/snowman.png"];
        treeTexture = [self setupTexture:@"Images/christmas_tree.png"];
        snowflakeTexture = [self setupTexture:@"Images/snowflake.png"];
        gloomieTexture = [self setupTexture:@"Images/gloomie.png"];

        gloomiesIsTrackingMatrix = NO;
        
        gloomies = [[Gloomies alloc] init];
	}

	return self;
}

- (void)dealloc {
	glDeleteBuffers(1, &m_objectVertexBuffer);
	glDeleteVertexArraysOES(1, &m_objectVertexArray);

	glDeleteBuffers(1, &m_treeVertexBuffer);
	glDeleteVertexArraysOES(1, &m_treeVertexArray);

	glDeleteBuffers(1, &m_snowflakeVertexBuffer);
	glDeleteVertexArraysOES(1, &m_snowflakeVertexArray);

	glDeleteBuffers(1, &m_gloomieVertexBuffer);
	glDeleteVertexArraysOES(1, &m_gloomieVertexArray);

	if (m_shaderProgram)
	{
		glDeleteProgram(m_shaderProgram);
		m_shaderProgram = 0;
	}
}

- (void)setGloomiesTargetWithTrackingValues:(metaio::TrackingValues)trackingValues modelViewMatrix:(GLKMatrix4)modelViewMatrix deviceMotion:(CMDeviceMotion *)deviceMotion {
    if (!gloomiesIsTrackingMatrix) {
        //[self translateGloomiesToTrackingValues:trackingValues];
        [self translateGloomiesFromModelViewMatrix:gloomiesModelViewMatrix toModelViewMatrix:modelViewMatrix];
        gloomiesIsTrackingMatrix = YES;
    }
    
    gloomiesModelViewMatrix = modelViewMatrix;
    gloomies.targetPosition = GLKVector3Make(0.0f, 0.0f, 100.0f);
}

- (void)setGloomiesTargetWithDeviceMotion:(CMDeviceMotion *)deviceMotion {
    gloomiesModelViewMatrix = GLKMatrix4Identity;
    gloomiesModelViewMatrix = GLKMatrix4Rotate(gloomiesModelViewMatrix, deviceMotion.attitude.roll, 1, 0, 0);
    gloomiesModelViewMatrix = GLKMatrix4Rotate(gloomiesModelViewMatrix, deviceMotion.attitude.pitch, 0, -1, 0);
    gloomiesModelViewMatrix = GLKMatrix4Rotate(gloomiesModelViewMatrix, deviceMotion.attitude.yaw, 0, 0, -1);

    gloomies.targetPosition = GLKVector3Make(0.0f, 300.0f, -200.0f);
}

- (void)translateGloomiesToTrackingValues:(metaio::TrackingValues)trackingValues {
    GLKMatrix4 m = GLKMatrix4Identity;
    /*m = GLKMatrix4RotateX(m, -trackingValues.rotation.getEulerAngleRadians().x);
    m = GLKMatrix4RotateX(m, -trackingValues.rotation.getEulerAngleRadians().y);
    m = GLKMatrix4RotateX(m, -trackingValues.rotation.getEulerAngleRadians().z);*/
    m = GLKMatrix4Translate(m, trackingValues.translation.x, trackingValues.translation.y, trackingValues.translation.z);
    GLKVector4 t = GLKMatrix4MultiplyVector4(m, GLKVector4Make(gloomies.averagePosition.x, gloomies.averagePosition.y, gloomies.averagePosition.z, 1.0f));
    GLKVector3 translation = GLKVector3Make(t.x, t.y, t.z);

    //GLKVector3 v = GLKVector3Subtract(GLKMatrix4MultiplyVector3(gloomiesModelViewMatrix, gloomies.averagePosition), GLKVector3Make(trackingValues.translation.x, trackingValues.translation.y, trackingValues.translation.z));
    //GLKVector3 translation = GLKVector3Subtract(gloomies.averagePosition, v);

    gloomies.targetPosition = GLKVector3Add(gloomies.targetPosition, translation);
    for (int i = 0; i < gloomies.individualsCount; i++) {
        gloomies.individuals[i]->position = GLKVector3Add(gloomies.individuals[i]->position, translation);
    }
}

- (void)translateGloomiesFromModelViewMatrix:(GLKMatrix4)modelViewMatrix1 toModelViewMatrix:(GLKMatrix4)modelViewMatrix2 {
    GLKMatrix4 inverseModelViewMatrix = [self invertMatrix:modelViewMatrix2];
    gloomies.targetPosition = [self translatePoint:gloomies.targetPosition fromModelViewMatrix:modelViewMatrix1 toInverseModelViewMatrix:inverseModelViewMatrix];
    for (int i = 0; i < gloomies.individualsCount; i++) {
        gloomies.individuals[i]->position = [self translatePoint:gloomies.individuals[i]->position fromModelViewMatrix:modelViewMatrix1 toInverseModelViewMatrix:inverseModelViewMatrix];
    }
}

- (GLKMatrix4)invertMatrix:(GLKMatrix4)matrix {
    bool isInvertible;
    GLKMatrix4 inverseMatrix = GLKMatrix4Invert(matrix, &isInvertible);
    if (isInvertible) {
        return inverseMatrix;
    } else {
        NSLog(@"Matrix not invertible!");
        return GLKMatrix4Identity;
    }
}

- (void)update:(CMDeviceMotion *)deviceMotion {
    for (int i = 0; i < SNOWFLAKES_COUNT; i++) {
        [self updateSnowflake:i];
    }
    for (int i = 0; i < 2; i++) {
        [gloomies update];
    }
}

- (GLKVector3)translatePoint:(GLKVector3)p fromModelViewMatrix:(GLKMatrix4)modelViewMatrix toInverseModelViewMatrix:(GLKMatrix4)inverseModelViewMatrix {
    GLKVector4 p1 = GLKMatrix4MultiplyVector4(modelViewMatrix, GLKVector4Make(p.x, p.y, p.z, 1.0f));
    GLKVector4 p2 = GLKMatrix4MultiplyVector4(inverseModelViewMatrix, p1);
    return GLKVector3Make(p2.x, p2.y, p2.z);
}

- (void)drawSnow:(CMDeviceMotion *)deviceMotion projectionMatrix:(GLKMatrix4)projectionMatrix {
	glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE);
    glDepthMask(false);

    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, deviceMotion.attitude.roll, 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, deviceMotion.attitude.pitch, 0, -1, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, deviceMotion.attitude.yaw, 0, 0, -1);

	glBindVertexArrayOES(m_snowflakeVertexArray);
    
	glUseProgram(m_shaderProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, snowflakeTexture.name);
    glUniform1i(textureSampler, 0);
    
    glUniform1f(textureAlpha, 0.9f);
    
	glBindBuffer(GL_ARRAY_BUFFER, m_snowflakeVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));

    for (int i = 0; i < SNOWFLAKES_COUNT; i++) {
        GLKMatrix4 m_modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, [self scaleAndTranslateModelView:[self snowflakeModelViewMatrix:modelViewMatrix index:i]]);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, m_modelViewProjectionMatrix.m);
    
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    
    // ----
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);

	glEnable(GL_ALPHA_TEST);
    glDepthMask(true);
}

- (void)drawGloomies:(CMDeviceMotion *)deviceMotion projectionMatrix:(GLKMatrix4)projectionMatrix {
	glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE);
    glDepthMask(false);
    
    GLKMatrix4 modelViewMatrix = gloomiesModelViewMatrix;
    
	glBindVertexArrayOES(m_gloomieVertexArray);
    
	glUseProgram(m_shaderProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gloomieTexture.name);
    glUniform1i(textureSampler, 0);
    
    glUniform1f(textureAlpha, 0.9f);
    
	glBindBuffer(GL_ARRAY_BUFFER, m_gloomieVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    for (int i = 0; i < gloomies.individualsCount; i++) {
        GLKMatrix4 m_modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, [self scaleAndTranslateModelView:[self gloomieModelViewMatrix:modelViewMatrix position:gloomies.individuals[i]->position]]);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, m_modelViewProjectionMatrix.m);
        
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    
    // ----
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);
    
	glEnable(GL_ALPHA_TEST);
    glDepthMask(true);
}

- (void)drawTreeWithModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glBindVertexArrayOES(m_treeVertexArray);
    
	glUseProgram(m_shaderProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, treeTexture.name);
    glUniform1i(textureSampler, 0);
    
    glUniform1f(textureAlpha, 1.0f);

	glBindBuffer(GL_ARRAY_BUFFER, m_treeVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    // ----
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, M_PI_2, 0.0f, 1.0f, 0.0f);

    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, M_PI_2, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = [self cylindricalBillboardMatrix:modelViewMatrix];

    GLKMatrix4 m_modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, [self scaleAndTranslateModelView:modelViewMatrix]);
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, m_modelViewProjectionMatrix.m);
    
	glDrawArrays(GL_TRIANGLES, 0, 36);
    // ----
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);
}

- (void)drawObject:(int)objectIndex withModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
	glBindVertexArrayOES(m_objectVertexArray);
    
	glUseProgram(m_shaderProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, objectTexture[objectIndex].name);
    glUniform1i(textureSampler, 0);
    
    glUniform1f(textureAlpha, 1.0f);
    
	glBindBuffer(GL_ARRAY_BUFFER, m_objectVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    // ----
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, M_PI_2, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, M_PI_2, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 100.0f, 0.0f, 100.0f);
    modelViewMatrix = [self cylindricalBillboardMatrix:modelViewMatrix];
    
    GLKMatrix4 m_modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, [self scaleAndTranslateModelView:modelViewMatrix]);
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, m_modelViewProjectionMatrix.m);
    
	glDrawArrays(GL_TRIANGLES, 0, 36);
    // ----
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);
}

- (GLKMatrix4)scaleAndTranslateModelView:(GLKMatrix4)m {
    const float scale = 40.0f;
    m = GLKMatrix4Translate(m, 0, 0, scale);
    m = GLKMatrix4Scale(m, scale, scale, scale);
    return m;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
	GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;

	// Create shader program.
	m_shaderProgram = glCreateProgram();

	// Create and compile vertex shader.
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
	{
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}

	// Create and compile fragment shader.
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
	if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
	{
		NSLog(@"Failed to compile fragment shader");
		return NO;
	}

	// Attach vertex shader to program.
	glAttachShader(m_shaderProgram, vertShader);

	// Attach fragment shader to program.
	glAttachShader(m_shaderProgram, fragShader);

	// Bind attribute locations.
	// This needs to be done prior to linking.
	glBindAttribLocation(m_shaderProgram, ATTRIB_VERTEX, "position");
	glBindAttribLocation(m_shaderProgram, ATTRIB_TEXCOORDS, "texCoords");
    
	// Link program.
	if (![self linkProgram:m_shaderProgram])
	{
		NSLog(@"Failed to link program: %d", m_shaderProgram);

		if (vertShader)
		{
			glDeleteShader(vertShader);
			vertShader = 0;
		}
		if (fragShader)
		{
			glDeleteShader(fragShader);
			fragShader = 0;
		}
		if (m_shaderProgram)
		{
			glDeleteProgram(m_shaderProgram);
			m_shaderProgram = 0;
		}

		return NO;
	}

	// Get uniform locations.
	uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(m_shaderProgram, "modelViewProjectionMatrix");

	// Release vertex and fragment shaders.
	if (vertShader)
	{
		glDetachShader(m_shaderProgram, vertShader);
		glDeleteShader(vertShader);
	}
	if (fragShader)
	{
		glDetachShader(m_shaderProgram, fragShader);
		glDeleteShader(fragShader);
	}

	return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
	GLint status;
	const GLchar *source;

	source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
	if (!source)
	{
		NSLog(@"Failed to load vertex shader");
		return NO;
	}

	*shader = glCreateShader(type);
	glShaderSource(*shader, 1, &source, NULL);
	glCompileShader(*shader);

#if defined(DEBUG)
	GLint logLength;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s", log);
		free(log);
	}
#endif

	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glDeleteShader(*shader);
		return NO;
	}

	return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
	GLint status;
	glLinkProgram(prog);

#if defined(DEBUG)
	GLint logLength;
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s", log);
		free(log);
	}
#endif

	glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0)
		return NO;

	return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
	GLint logLength, status;

	glValidateProgram(prog);
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}

	glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
	if (status == GL_FALSE)
		return NO;

	return YES;
}

- (GLKTextureInfo *)setupTexture:(NSString *)filename {
    NSError *error;
    GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filename ofType:nil]
                                                                  options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft]
                                                                    error:&error];
    if (error != nil) {
        NSLog(@"Failed to load image %@", filename);
        NSLog(@"Reason: %@", error.description);
        exit(1);
    }
    return texture;
}

- (GLKMatrix4)billboardMatrix:(GLKMatrix4)m {
	for (int i=0; i < 3; i++) {
	    for (int j=0; j < 3; j++) {
            m.m[i*4+j] = i == j ? 1.0f : 0.0f;
	    }
    }
    return m;
}

- (GLKMatrix4)cylindricalBillboardMatrix:(GLKMatrix4)m {
	for (int i=0; i < 3; i += 2) {
	    for (int j=0; j < 3; j++) {
            m.m[i*4+j] = i == j ? 1.0f : 0.0f;
	    }
    }
    return m;
}

- (GLKMatrix4)snowflakeModelViewMatrix:(GLKMatrix4)modelViewMatrix index:(int)i {
    float animationRadius = 10.0f;
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,
                                          snowflakes[i].position.x + cosf(snowflakes[i].animation) * animationRadius,
                                          snowflakes[i].position.y + sinf(snowflakes[i].animation) * animationRadius,
                                          snowflakes[i].position.z);
    return [self billboardMatrix:modelViewMatrix];
}

- (GLKMatrix4)gloomieModelViewMatrix:(GLKMatrix4)modelViewMatrix position:(GLKVector3)position {
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,
                                          position.x,
                                          position.y,
                                          position.z);
    return [self billboardMatrix:modelViewMatrix];
}

- (void)resetSnowflake:(int)i random:(bool)random {
    const float minVelocity = 1.0f;
    const float maxVelocity = 2.0f;
    
    snowflakes[i].position.x = (((float)rand() / (float)RAND_MAX) * snowflakesMaxXZ) - (snowflakesMaxXZ / 2.0f);
    snowflakes[i].position.y = (((float)rand() / (float)RAND_MAX) * snowflakesMaxXZ) - (snowflakesMaxXZ / 2.0f);
    snowflakes[i].position.z = random ? (((float)rand() / (float)RAND_MAX) * snowflakesMaxY) - (snowflakesMaxY / 2.0f) : (snowflakesMaxY / 2.0f);
    
    snowflakes[i].velocity.x = 0.0f;
    snowflakes[i].velocity.y = 0.0f;
    snowflakes[i].velocity.z = -((((float)rand() / (float)RAND_MAX) * (maxVelocity - minVelocity)) + minVelocity);
    
    snowflakes[i].animation = ((float)rand() / (float)RAND_MAX) * M_PI * 2.0f;
}

- (void)updateSnowflake:(int)i {
    const float animationSpeed = 0.1f;
    
    snowflakes[i].position.x += snowflakes[i].velocity.x;
    snowflakes[i].position.y += snowflakes[i].velocity.y;
    snowflakes[i].position.z += snowflakes[i].velocity.z;
    
    snowflakes[i].animation += animationSpeed;
    
    if (snowflakes[i].position.z < -snowflakesMaxY / 2.0f) {
        [self resetSnowflake:i random:NO];
    }
}

@end