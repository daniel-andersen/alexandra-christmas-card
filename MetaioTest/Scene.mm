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

const float treeScaleX = 2.0f;
const float treeScaleY = 2.0f;

const float snowflakeScaleX = 0.035f;
const float snowflakeScaleY = 0.035f;

const float gloomieScaleX = 0.3f;
const float gloomieScaleY = 0.3f;

const float treeGloomieScaleX = 1.5f;
const float treeGloomieScaleY = 1.5f;

const float giftScale = 0.5f;

const int treeGloomiesCount = 13;

GLKVector3 treeGloomiesTranslation[treeGloomiesCount];
float treeGloomiesScale[treeGloomiesCount];

const float treeWidth = 150.0f;
const float treeHeight = 300.0f;
const float treeYOffset = 20.0f;

const float giftSize = 20.0f;
GLKVector3 giftPosition[giftCount];

const float arrowSize = 30.0f;

const float seekingNewPositionDelay = 5.0f;

const float cameraAlphaSpeed = 0.02f;

const Vertex gObjectVertexData[] = {
	{.position = { objectScaleX, -objectScaleY, -1.0f}, .texCoord = {1.0f, 0.0f}},
	{.position = {-objectScaleX, -objectScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = { objectScaleX,  objectScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = { objectScaleX,  objectScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = {-objectScaleX, -objectScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = {-objectScaleX,  objectScaleY, -1.0f}, .texCoord = {0.0f, 1.0f}},
};

const Vertex gGiftVertexData[] = {
	{.position = { giftScale, -giftScale, -giftScale}, .texCoord = {1.0f, 0.0f}},
	{.position = {-giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = { giftScale,  giftScale, -giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = { giftScale,  giftScale, -giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = {-giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = {-giftScale,  giftScale, -giftScale}, .texCoord = {0.0f, 1.0f}},

	{.position = { giftScale, -giftScale,  giftScale}, .texCoord = {1.0f, 0.0f}},
	{.position = {-giftScale, -giftScale,  giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = { giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = { giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = {-giftScale, -giftScale,  giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = {-giftScale,  giftScale,  giftScale}, .texCoord = {0.0f, 1.0f}},

	{.position = {-giftScale,  giftScale, -giftScale}, .texCoord = {1.0f, 0.0f}},
	{.position = {-giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = {-giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = {-giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = {-giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = {-giftScale, -giftScale,  giftScale}, .texCoord = {0.0f, 1.0f}},

	{.position = { giftScale,  giftScale, -giftScale}, .texCoord = {1.0f, 0.0f}},
	{.position = { giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = { giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = { giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = { giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = { giftScale, -giftScale,  giftScale}, .texCoord = {0.0f, 1.0f}},

	{.position = { giftScale,  giftScale, -giftScale}, .texCoord = {1.0f, 0.0f}},
	{.position = {-giftScale,  giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = { giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = { giftScale,  giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = {-giftScale,  giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = {-giftScale,  giftScale,  giftScale}, .texCoord = {0.0f, 1.0f}},

	{.position = { giftScale, -giftScale, -giftScale}, .texCoord = {1.0f, 0.0f}},
	{.position = {-giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = { giftScale, -giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = { giftScale, -giftScale,  giftScale}, .texCoord = {1.0f, 1.0f}},
	{.position = {-giftScale, -giftScale, -giftScale}, .texCoord = {0.0f, 0.0f}},
	{.position = {-giftScale, -giftScale,  giftScale}, .texCoord = {0.0f, 1.0f}},
};

const Vertex gTreeGloomieVertexData[] = {
	{.position = { treeGloomieScaleX, -treeGloomieScaleY, -1.0f}, .texCoord = {1.0f, 0.0f}},
	{.position = {-treeGloomieScaleX, -treeGloomieScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = { treeGloomieScaleX,  treeGloomieScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = { treeGloomieScaleX,  treeGloomieScaleY, -1.0f}, .texCoord = {1.0f, 1.0f}},
	{.position = {-treeGloomieScaleX, -treeGloomieScaleY, -1.0f}, .texCoord = {0.0f, 0.0f}},
	{.position = {-treeGloomieScaleX,  treeGloomieScaleY, -1.0f}, .texCoord = {0.0f, 1.0f}},
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

	GLuint	m_treeGloomieVertexArray;
	GLuint	m_treeGloomieVertexBuffer;

	GLuint	m_snowflakeVertexArray;
	GLuint	m_snowflakeVertexBuffer;

	GLuint	m_gloomieVertexArray;
	GLuint	m_gloomieVertexBuffer;

	GLuint	m_giftVertexArray;
	GLuint	m_giftVertexBuffer;

    GLKTextureInfo *objectTexture[OBJECT_COUNT];
    GLKTextureInfo *giftTexture[giftCount];
    GLKTextureInfo *snowflakeTexture;
    GLKTextureInfo *gloomieTexture;
    GLKTextureInfo *treeGloomieTexture;

    GLuint textureSampler;
    GLuint textureAlpha;
    
    GLKMatrix4 gloomiesModelViewMatrix;
    bool gloomiesIsTrackingMatrix;
    bool gloomiesShowingTree;
    
    Snowflake snowflakes[SNOWFLAKES_COUNT];
    
    float treeGloomieAlpha;
    float animation;
    int gloomiesTargetMode;
    
    CFTimeInterval viewingGiftStartTime;
    
    GLKVector3 arrowCenter;

    GLKVector3 seekingSlowSource;
    GLKVector3 seekingSlowDestination;
    CFTimeInterval seekingArrivalTime;
    
    bool isFirstTimeShowingTree;
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
		glGenVertexArraysOES(1, &m_treeGloomieVertexArray);
		glBindVertexArrayOES(m_treeGloomieVertexArray);
        
		glGenBuffers(1, &m_treeGloomieVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, m_treeGloomieVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(gTreeGloomieVertexData), gTreeGloomieVertexData, GL_STATIC_DRAW);
        
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

        // Gift
		glGenVertexArraysOES(1, &m_giftVertexArray);
		glBindVertexArrayOES(m_giftVertexArray);
        
		glGenBuffers(1, &m_giftVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, m_giftVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(gGiftVertexData), gGiftVertexData, GL_STATIC_DRAW);
        
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
		glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));

        // Textures
        glBindVertexArrayOES(0);
        
        textureSampler = glGetUniformLocation(m_shaderProgram, "texture");
        textureAlpha = glGetUniformLocation(m_shaderProgram, "alpha");

        objectTexture[0] = [self setupTexture:@"Images/snowman.png"];
        treeGloomieTexture = [self setupTexture:@"Images/tree_gloomie.png"];
        snowflakeTexture = [self setupTexture:@"Images/snowflake.png"];
        gloomieTexture = [self setupTexture:@"Images/gloomie.png"];
        for (int i = 0; i < giftCount; i++) {
            giftTexture[i] = [self setupTexture:[NSString stringWithFormat:@"Images/gift%i.png", i + 1]];
        }

        gloomiesIsTrackingMatrix = NO;
        gloomiesShowingTree = NO;
        animation = 0.0f;
        gloomiesTargetMode = GLOOMIES_TARGET_NONE;
        
        treeGloomiesTranslation[ 0] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 0.0f) height:0.0f];                       treeGloomiesScale[ 0] = 0.75f;
        treeGloomiesTranslation[ 1] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 1.0f) height:0.0f];                       treeGloomiesScale[ 1] = 0.75f;
        treeGloomiesTranslation[ 2] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 2.0f) height:0.0f];                       treeGloomiesScale[ 2] = 0.75f;
        treeGloomiesTranslation[ 3] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 3.0f) height:0.0f];                       treeGloomiesScale[ 3] = 0.75f;
        treeGloomiesTranslation[ 4] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 0.0f) height:treeHeight];                 treeGloomiesScale[ 4] = 1.0f;
        treeGloomiesTranslation[ 5] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 0.0f) height:(treeHeight * 1.0f / 3.0f)]; treeGloomiesScale[ 5] = 0.75f;
        treeGloomiesTranslation[ 6] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 0.0f) height:(treeHeight * 2.0f / 3.0f)]; treeGloomiesScale[ 6] = 0.75f;
        treeGloomiesTranslation[ 7] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 1.0f) height:(treeHeight * 1.0f / 3.0f)]; treeGloomiesScale[ 7] = 0.75f;
        treeGloomiesTranslation[ 8] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 1.0f) height:(treeHeight * 2.0f / 3.0f)]; treeGloomiesScale[ 8] = 0.75f;
        treeGloomiesTranslation[ 9] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 2.0f) height:(treeHeight * 1.0f / 3.0f)]; treeGloomiesScale[ 9] = 0.75f;
        treeGloomiesTranslation[10] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 2.0f) height:(treeHeight * 2.0f / 3.0f)]; treeGloomiesScale[10] = 0.75f;
        treeGloomiesTranslation[11] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 3.0f) height:(treeHeight * 1.0f / 3.0f)]; treeGloomiesScale[11] = 0.75f;
        treeGloomiesTranslation[12] = [self treeGloomieOffsetFromAngle:(M_PI_2 * 3.0f) height:(treeHeight * 2.0f / 3.0f)]; treeGloomiesScale[12] = 0.75f;

        giftPosition[0] = GLKVector3Make(  75.0f,   90.0f, 0.0f);
        giftPosition[1] = GLKVector3Make(  50.0f,  -75.0f, 0.0f);
        giftPosition[2] = GLKVector3Make( -90.0f,   40.0f, 0.0f);
        giftPosition[3] = GLKVector3Make( -75.0f,  -50.0f, 0.0f);
        
        self.giftNumber = 0;
        
        gloomies = [[Gloomies alloc] init];

        self.cameraAlpha = 1.0f;
        
        isFirstTimeShowingTree = YES;
	}

	return self;
}

- (GLKVector3)treeGloomieOffsetFromAngle:(float)angle height:(float)height {
    float radius = treeWidth * ((treeHeight - height) / treeHeight);
    return GLKVector3Make(cosf(angle) * radius, sinf(angle) * radius, treeYOffset + height);
}

- (void)dealloc {
	glDeleteBuffers(1, &m_objectVertexBuffer);
	glDeleteVertexArraysOES(1, &m_objectVertexArray);

	glDeleteBuffers(1, &m_treeGloomieVertexBuffer);
	glDeleteVertexArraysOES(1, &m_treeGloomieVertexArray);

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

- (void)setGloomiesTargetWithTrackingValues:(metaio::TrackingValues)trackingValues modelViewMatrix:(GLKMatrix4)modelViewMatrix deviceMotion:(CMDeviceMotion *)deviceMotion targetMode:(int)targetMode {
    gloomiesTargetMode = targetMode;
    
    if (!gloomiesIsTrackingMatrix) {
        [self translateGloomiesFromModelViewMatrix:gloomiesModelViewMatrix toModelViewMatrix:modelViewMatrix];
        gloomiesIsTrackingMatrix = YES;
        gloomiesShowingTree = NO;
        treeGloomieAlpha = 0.0f;
    }
    
    gloomiesModelViewMatrix = modelViewMatrix;
}

- (void)setGloomiesTargetWithDeviceMotion:(CMDeviceMotion *)deviceMotion targetMode:(int)targetMode {
    gloomiesTargetMode = targetMode;

    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, deviceMotion.attitude.roll, 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, deviceMotion.attitude.pitch, 0, -1, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, deviceMotion.attitude.yaw, 0, 0, -1);

    if (gloomiesIsTrackingMatrix) {
        [self translateGloomiesFromModelViewMatrix:gloomiesModelViewMatrix toModelViewMatrix:modelViewMatrix];
        gloomiesIsTrackingMatrix = NO;
    }

    gloomiesModelViewMatrix = modelViewMatrix;
}

- (void)translateGloomiesFromModelViewMatrix:(GLKMatrix4)modelViewMatrix1 toModelViewMatrix:(GLKMatrix4)modelViewMatrix2 {
    GLKMatrix4 inverseModelViewMatrix = [self invertMatrix:modelViewMatrix2];
    gloomies.targetPosition = [self translatePoint:gloomies.targetPosition fromModelViewMatrix:modelViewMatrix1 toInverseModelViewMatrix:inverseModelViewMatrix];
    gloomies.averagePosition = [self translatePoint:gloomies.averagePosition fromModelViewMatrix:modelViewMatrix1 toInverseModelViewMatrix:inverseModelViewMatrix];
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

- (void)startShowingArrow {
    [self randomGloomiesDestinationAwayFromCamera];
    arrowCenter = GLKVector3Make(0.0f, 0.0f, 0.0f);
}

- (void)startShowingGift {
    viewingGiftStartTime = CFAbsoluteTimeGetCurrent();
    isFirstTimeShowingTree = NO;
}

- (void)startViewingObject {
    gloomies.targetPosition = gloomies.averagePosition;
}

- (void)randomGloomiesDestinationAwayFromCamera {
    [self randomGloomiesDestination];
    seekingArrivalTime = 0.0f;
}

- (void)randomGloomiesDestination {
    float distance = 750.0f;
    float a1 = ((float)rand() / (float)RAND_MAX) * M_PI * 2.0f;
    float a2 = (((float)rand() / (float)RAND_MAX) * 2.0f) - 1.0f;
    gloomies.targetPosition = GLKVector3Make(cosf(a1) * distance, sinf(a1) * distance, 200.0f * a2);

    a1 += M_PI / 4.0f;
    seekingSlowSource = gloomies.targetPosition;
    seekingSlowDestination = GLKVector3Make(cosf(a1) * distance, sinf(a1) * distance, 200.0f * a2);
    
    seekingArrivalTime = 0.0f;
}

- (void)update:(CMDeviceMotion *)deviceMotion {
    for (int i = 0; i < SNOWFLAKES_COUNT; i++) {
        [self updateSnowflake:i];
    }
    [self updateCameraAlpha];
    animation += 0.02f;
    if (gloomiesTargetMode != GLOOMIES_TARGET_SEEKING_OBJECT) {
        seekingArrivalTime = -1.0f;
    }
    if (gloomiesIsTrackingMatrix) {
        gloomiesShowingTree |= [self gloomiesDistanceToTree] < treeWidth * 1.5f;
        if (gloomiesShowingTree) {
            treeGloomieAlpha = MIN(treeGloomieAlpha + 0.05f, 1.0f);
        }
    } else {
        gloomiesShowingTree = NO;
    }
    [self setGloomiesTarget];
    [self calculateDistanceToTrackedObject];
    for (int i = 0; i < 2; i++) {
        [gloomies update];
    }
}

- (void)calculateDistanceToTrackedObject {
    if (gloomiesIsTrackingMatrix) {
        GLKVector4 p = GLKMatrix4MultiplyVector4(gloomiesModelViewMatrix, GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f));
        self.distanceToTrackedObject = GLKVector3Length(GLKVector3Make(p.x, p.y, p.z));
    } else {
        self.distanceToTrackedObject = 10000.0f;
    }
}

- (void)updateCameraAlpha {
    float destAlpha = 1.0f;
    if (gloomiesIsTrackingMatrix && (gloomiesTargetMode == GLOOMIES_TARGET_TREE || gloomiesTargetMode == GLOOMIES_TARGET_GIFT)) {
        destAlpha = 0.3f;
    }
    if (self.cameraAlpha < destAlpha) {
        self.cameraAlpha += cameraAlphaSpeed;
    }
    if (self.cameraAlpha > destAlpha) {
        self.cameraAlpha -= cameraAlphaSpeed;
    }
    self.cameraAlpha = MIN(1.0f, MAX(0.0f, self.cameraAlpha));
}

- (void)setGloomiesTarget {
    gloomies.individualTargets = NO;
    if (gloomiesIsTrackingMatrix) {
        if (gloomiesShowingTree) {
            gloomies.individualTargets = YES;
            if (gloomiesTargetMode == GLOOMIES_TARGET_TREE) {
                [self setGloomiesTargetTree];
            } else if (gloomiesTargetMode == GLOOMIES_TARGET_GIFT) {
                [self setGloomiesTargetGift];
            } else if (gloomiesTargetMode == GLOOMIES_TARGET_VIEWING_OBJECT) {
                gloomies.individualTargets = NO;
                [self setGloomiesTargetObject];
            } else if (gloomiesTargetMode == GLOOMIES_TARGET_PLACE_OBJECT) {
                gloomies.individualTargets = NO;
                [self setGloomiesTargetPlaceObject];
            }
        } else {
            gloomies.targetPosition = GLKVector3Make(0.0f, 0.0f, treeYOffset + (treeHeight / 2.0f));
        }
    } else {
        if (gloomiesTargetMode == GLOOMIES_TARGET_ARROW) {
            gloomies.individualTargets = YES;
            [self setGloomiesTargetArrow];
        } else if (gloomiesTargetMode == GLOOMIES_TARGET_SEEKING_OBJECT) {
            [self setGloomiesTargetRandom];
        } else if (gloomiesTargetMode == GLOOMIES_TARGET_BRINGING_OBJECT_HOME) {
            [self setGloomiesTargetBringingObjectHome];
        } else {
            [self setGloomiesTargetScreen];
        }
    }
}

- (void)setGloomiesTargetRandom {
    if (seekingArrivalTime == -1.0f) {
        [self randomGloomiesDestinationAwayFromCamera];
        seekingArrivalTime = 0.0f;
    }
    if ([self gloomiesDistanceToTarget] < 50.0f) {
        if (seekingArrivalTime == 0.0f) {
            seekingArrivalTime = CFAbsoluteTimeGetCurrent();
        }
    }
    if (seekingArrivalTime != 0.0f) {
        if (CFAbsoluteTimeGetCurrent() > seekingArrivalTime + seekingNewPositionDelay) {
            [self randomGloomiesDestination];
        } else {
            float t = (CFAbsoluteTimeGetCurrent() - seekingArrivalTime) / seekingNewPositionDelay;
            GLKVector3 d = GLKVector3Subtract(seekingSlowDestination, seekingSlowSource);
            gloomies.targetPosition = GLKVector3Make(seekingSlowSource.x - (d.x * t),
                                                     seekingSlowSource.y - (d.y * t),
                                                     seekingSlowSource.z - (d.z * t));
        }
    }
}

- (void)setGloomiesTargetTree {
    for (int i = 0; i < gloomies.individualsCount; i++) {
        float targetHeight = treeHeight * ((float)i / gloomies.individualsCount) * ((float)i / gloomies.individualsCount);
        float targetAngle = (animation * gloomies.individuals[i]->randomSpeed) + ((float)i * 2.0f);
        gloomies.individuals[i]->targetPosition = [self treeGloomieOffsetFromAngle:targetAngle height:targetHeight];
    }
}

- (void)setGloomiesTargetPlaceObject {
    gloomies.targetPosition = giftPosition[self.giftNumber];
}

- (void)setGloomiesTargetBringingObjectHome {
    [self setGloomiesTargetScreen];
}

- (void)setGloomiesTargetScreen {
    GLKMatrix4 inverseMatrix = [self invertMatrix:gloomiesModelViewMatrix];
    GLKVector4 p = GLKMatrix4MultiplyVector4(inverseMatrix, GLKVector4Make(0.0f, 0.0f, -300.0f, 1.0f));
    gloomies.targetPosition = GLKVector3Make(p.x, p.y, p.z);
}

- (void)setGloomiesTargetObject {
    gloomies.targetPosition = GLKVector3Make(0.0f, 0.0f, 40.0f);
}

- (void)setGloomiesTargetGift {
    int gloomiesPerSide = gloomies.individualsCount / 12;
    float stepSize = (giftSize * 2.0f) / (float)gloomiesPerSide;

    GLKVector3 t = giftPosition[self.giftNumber];

    for (int i = 0; i < gloomiesPerSide; i++) {
        float step = (float)i * stepSize;

        int off = i;
        
        gloomies.individuals[off + (gloomiesPerSide *  0)]->targetPosition = GLKVector3Make(t.x - giftSize + step, t.y + giftSize,        t.z + giftSize);
        gloomies.individuals[off + (gloomiesPerSide *  1)]->targetPosition = GLKVector3Make(t.x - giftSize + step, t.y - giftSize,        t.z + giftSize);
        gloomies.individuals[off + (gloomiesPerSide *  2)]->targetPosition = GLKVector3Make(t.x - giftSize,        t.y - giftSize + step, t.z + giftSize);
        gloomies.individuals[off + (gloomiesPerSide *  3)]->targetPosition = GLKVector3Make(t.x + giftSize,        t.y - giftSize + step, t.z + giftSize);

        gloomies.individuals[off + (gloomiesPerSide *  4)]->targetPosition = GLKVector3Make(t.x - giftSize + step, t.y + giftSize,        t.z - giftSize);
        gloomies.individuals[off + (gloomiesPerSide *  5)]->targetPosition = GLKVector3Make(t.x - giftSize + step, t.y - giftSize,        t.z - giftSize);
        gloomies.individuals[off + (gloomiesPerSide *  6)]->targetPosition = GLKVector3Make(t.x - giftSize,        t.y - giftSize + step, t.z - giftSize);
        gloomies.individuals[off + (gloomiesPerSide *  7)]->targetPosition = GLKVector3Make(t.x + giftSize,        t.y - giftSize + step, t.z - giftSize);

        gloomies.individuals[off + (gloomiesPerSide *  8)]->targetPosition = GLKVector3Make(t.x - giftSize,        t.y - giftSize,        t.z - giftSize + step);
        gloomies.individuals[off + (gloomiesPerSide *  9)]->targetPosition = GLKVector3Make(t.x - giftSize,        t.y + giftSize,        t.z - giftSize + step);
        gloomies.individuals[off + (gloomiesPerSide * 10)]->targetPosition = GLKVector3Make(t.x + giftSize,        t.y - giftSize,        t.z - giftSize + step);
        gloomies.individuals[off + (gloomiesPerSide * 11)]->targetPosition = GLKVector3Make(t.x + giftSize,        t.y + giftSize,        t.z - giftSize + step);
    }
}

- (void)setGloomiesTargetArrow {
    int arrowLineCount = gloomies.individualsCount * 2 / 3;
    //int arrowHeadCount = (gloomies.individualsCount - arrowLineCount) / 2;

    if (GLKVector3AllEqualToScalar(arrowCenter, 0.0f)) {
        arrowCenter = gloomies.averagePosition;
    }
    
    GLKVector3 dir = GLKVector3Subtract(arrowCenter, gloomies.targetPosition);
    float len = sqrtf((dir.x * dir.x) +
                      (dir.y * dir.y) +
                      (dir.z * dir.z));
    if (len <= 0.0f) {
        return;
    }
    dir.x /= len;
    dir.y /= len;
    dir.z /= len;

    for (int i = 0; i < arrowLineCount; i++) {
        float t = ((float)i / (float)arrowLineCount) - 0.5f;
        gloomies.individuals[i]->targetPosition = GLKVector3Make(arrowCenter.x + (dir.x * t), arrowCenter.y + (dir.y * t), arrowCenter.z);
    }
}

- (float)gloomiesDistanceToTree {
    return sqrtf((gloomies.averagePosition.x * gloomies.averagePosition.x) +
                 (gloomies.averagePosition.y * gloomies.averagePosition.y) +
                 (gloomies.averagePosition.z * gloomies.averagePosition.z));
}

- (float)gloomiesDistanceToTarget {
    GLKVector3 d = GLKVector3Subtract(gloomies.averagePosition, gloomies.targetPosition);
    return sqrtf((d.x * d.x) +
                 (d.y * d.y) +
                 (d.z * d.z));
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
    
        glDrawArrays(GL_TRIANGLES, 0, 6);
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
        
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
    
    // ----
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);
    
	glEnable(GL_ALPHA_TEST);
    glDepthMask(true);
}

- (void)drawTreeGloomiesWithModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix {
	glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glDepthMask(false);

	glBindVertexArrayOES(m_treeGloomieVertexArray);
    
	glUseProgram(m_shaderProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, treeGloomieTexture.name);
    glUniform1i(textureSampler, 0);
    
	glBindBuffer(GL_ARRAY_BUFFER, m_treeGloomieVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    for (int i = 0; i < treeGloomiesCount; i++) {
        glUniform1f(textureAlpha, treeGloomieAlpha * MAX(0.0f, MIN(1.0f, cosf((animation * 2.5f) + (i * 2.0f)) + 1.5f)));

        GLKMatrix4 modelViewMatrix1 = GLKMatrix4Translate(modelViewMatrix, treeGloomiesTranslation[i].x, treeGloomiesTranslation[i].y, treeGloomiesTranslation[i].z);
        modelViewMatrix1 = [self billboardMatrix:modelViewMatrix1];
        modelViewMatrix1 = GLKMatrix4Scale(modelViewMatrix1, treeGloomiesScale[i], treeGloomiesScale[i], treeGloomiesScale[i]);
        modelViewMatrix1 = [self scaleAndTranslateModelView:modelViewMatrix1];
        
        GLKMatrix4 m_modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix1);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, m_modelViewProjectionMatrix.m);
    
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }

    // ---
    glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);

	glEnable(GL_ALPHA_TEST);
    glDepthMask(true);
}

- (void)drawGiftWithProjectionMatrix:(GLKMatrix4)projectionMatrix {
    GLKMatrix4 modelViewMatrix = gloomiesModelViewMatrix;
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,
                                          gloomies.averagePosition.x,
                                          gloomies.averagePosition.y,
                                          gloomies.averagePosition.z - 40.0f);
    [self drawGiftWithModelViewMatrix:modelViewMatrix projectionMatrix:projectionMatrix];
    
}

- (void)drawGiftWithModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix {
    [self drawGift2:self.giftNumber withModelViewMatrix:modelViewMatrix projectionMatrix:projectionMatrix];
}

- (void)drawGift:(int)index withModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix {
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,
                                          giftPosition[index].x,
                                          giftPosition[index].y,
                                          giftPosition[index].z);
    [self drawGift2:index withModelViewMatrix:modelViewMatrix projectionMatrix:projectionMatrix];
}

- (void)drawGift2:(int)index withModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
	glBindVertexArrayOES(m_giftVertexArray);
    
	glUseProgram(m_shaderProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, giftTexture[index].name);
    glUniform1i(textureSampler, 0);
    
    glUniform1f(textureAlpha, gloomiesTargetMode == GLOOMIES_TARGET_TREE && index < self.giftNumber - 1 ? treeGloomieAlpha : 1.0f);
    
	glBindBuffer(GL_ARRAY_BUFFER, m_giftVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
    glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_TRUE, sizeof(Vertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    // ---
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
    
	glDrawArrays(GL_TRIANGLES, 0, 6);
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
    modelViewMatrix = [self billboardMatrix:modelViewMatrix];
    return modelViewMatrix;
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
