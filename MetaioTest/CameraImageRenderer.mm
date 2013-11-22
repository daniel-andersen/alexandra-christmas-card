#import "CameraImageRenderer.h"

#import <GLKit/GLKit.h>
#include <OpenGLES/EAGL.h>
#include <OpenGLES/ES2/gl.h>
#include <metaioSDK/IMetaioSDK.h>

#define BUFFER_OFFSET(i) ((uint8_t *)NULL + (i))

#if !IOS_FAST_TEXTURE_UPLOAD

static int getNextPowerOf2(int value)
{
	for (int i = 0; i < 12; ++i)
	{
		if ((1 << i) >= value)
			return 1 << i;
	}

	NSLog(@"Value too large");
	return 0;
}

#endif // !IOS_FAST_TEXTURE_UPLOAD

static float gVertexData[] =
{
	-1, -1, 0,
	 1, -1, 0,
	-1,  1, 0,
	 1,  1, 0
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
	NUM_UNIFORMS
};

@implementation CameraImageRenderer
{
	GLKMatrix4 m_modelViewProjectionMatrix;

	GLint m_uniforms[NUM_UNIFORMS];
}

- (void)dealloc
{
	if (m_initialized)
	{
		glDeleteBuffers(1, &m_texCoordsBuffer);
		glDeleteVertexArraysOES(1, &m_texCoordsArray);

		glDeleteBuffers(1, &m_vertexBuffer);
		glDeleteVertexArraysOES(1, &m_vertexArray);

		if (m_shaderProgram)
		{
			glDeleteProgram(m_shaderProgram);
			m_shaderProgram = 0;
		}

#if IOS_FAST_TEXTURE_UPLOAD

		if (m_cvTexture)
		{
			CFRelease(m_cvTexture);
			m_cvTexture = NULL;
		}

		if (m_cvTextureCache)
		{
			CFRelease(m_cvTextureCache);
			m_cvTextureCache = NULL;
		}

#else

		glDeleteTextures(1, &m_texture);
		m_texture = 0;

#endif // IOS_FAST_TEXTURE_UPLOAD
	}

#if !IOS_FAST_TEXTURE_UPLOAD

	if (m_pTextureBuffer)
	{
		delete[] m_pTextureBuffer;
		m_pTextureBuffer = NULL;
	}

#endif // !IOS_FAST_TEXTURE_UPLOAD
}

/**
 * Renders the current camera image
 *
 * @param screenAspect Aspect ratio of the rendering area (in the given orientation)
 */
- (void)draw:(metaio::ESCREEN_ROTATION)screenRotation renderTargetAspect:(float)screenAspect
{
	if (!m_initialized)
		return;

#if IOS_FAST_TEXTURE_UPLOAD

	glBindTexture(m_lastCvTextureTarget, m_lastCvTextureName);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

#else

	glBindTexture(GL_TEXTURE_2D, m_texture);

#endif // IOS_FAST_TEXTURE_UPLOAD

	if (m_mustUpdateTexture)
	{
#if IOS_FAST_TEXTURE_UPLOAD

		const float xRatio = 1, yRatio = 1;

#else

		if (!m_textureInitialized)
		{
			// Allocate camera image texture once with 2^n dimensions
			glTexImage2D(
				GL_TEXTURE_2D,
				0,
				GL_RGBA,
				m_textureWidth,
				m_textureHeight,
				0,
				GL_BGRA,
				GL_UNSIGNED_BYTE,
				NULL);

			m_textureInitialized = true;
		}

		// ...but only overwrite the camera image-sized region
		glTexSubImage2D(
			GL_TEXTURE_2D,
			0,
			0,
			0,
			m_cameraImageWidth,
			m_cameraImageHeight,
			GL_BGRA,
			GL_UNSIGNED_BYTE,
			m_pTextureBuffer);

		const float xRatio = (float)m_cameraImageWidth / m_textureWidth;
		const float yRatio = (float)m_cameraImageHeight / m_textureHeight;

#endif // IOS_FAST_TEXTURE_UPLOAD

		const bool cameraIsRotated = screenRotation == metaio::ESCREEN_ROTATION_90 ||
		                             screenRotation == metaio::ESCREEN_ROTATION_270;
		const float cameraAspect = cameraIsRotated ? 1.0f/m_cameraAspect : m_cameraAspect;

		float offsetX, offsetY;

		if (cameraAspect > screenAspect)
		{
			// Camera image is wider (e.g. 480x640 camera image vs. a 480x800 device, example
			// in portrait mode), so crop the width of the camera image
			float aspectRatio = screenAspect / cameraAspect;
			offsetX = 0.5f * (1 - aspectRatio);
			offsetY = 0;

			m_scaleX = cameraAspect / screenAspect;
			m_scaleY = 1;
		}
		else
		{
			// Screen is wider, so crop the height of the camera image
			float aspectRatio = cameraAspect / screenAspect;
			offsetY = 0.5f * (1 - aspectRatio);
			offsetX = 0;

			m_scaleX = 1;
			m_scaleY = screenAspect / cameraAspect;
		}

		if (cameraIsRotated)
		{
			// Camera image will be rendered with +-90° rotation, so switch UV coordinates
			float tmp = offsetX;
			offsetX = offsetY;
			offsetY = tmp;
		}

		// Calculate texture coordinates. offsetX/offsetY are for cropping if camera and screen
		// aspect ratios differ. xRatio/yRatio are here because the OpenGL texture has
		// dimensions of 2^n, but the camera image does not fill it completely (e.g. camera
		// image 640x480 vs. texture size 1024x512).
		GLfloat texCoordsRawBuffer[2*4];
		texCoordsRawBuffer[0] = offsetX * xRatio;
		texCoordsRawBuffer[1] = (1-offsetY) * yRatio;

		texCoordsRawBuffer[2] = (1-offsetX) * xRatio;
		texCoordsRawBuffer[3] = (1-offsetY) * yRatio;

		texCoordsRawBuffer[4] = offsetX * xRatio;
		texCoordsRawBuffer[5] = offsetY * yRatio;

		texCoordsRawBuffer[6] = (1-offsetX) * xRatio;
		texCoordsRawBuffer[7] = offsetY * yRatio;

		glBindBuffer(GL_ARRAY_BUFFER, m_texCoordsBuffer);
		glBufferData(GL_ARRAY_BUFFER, 2*4*4, texCoordsRawBuffer, GL_STATIC_DRAW);

		m_mustUpdateTexture = false;
	}

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glUseProgram(m_shaderProgram);

	glBindBuffer(GL_ARRAY_BUFFER, m_vertexBuffer);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 12, BUFFER_OFFSET(0));
	glBindBuffer(GL_ARRAY_BUFFER, m_texCoordsBuffer);
	glEnableVertexAttribArray(ATTRIB_TEXCOORDS);
	glVertexAttribPointer(ATTRIB_TEXCOORDS, 2, GL_FLOAT, GL_FALSE, 8, BUFFER_OFFSET(0));

	switch (screenRotation)
	{
		// Portrait
		case metaio::ESCREEN_ROTATION_270:
			// Rotate by 90° clockwise
			m_modelViewProjectionMatrix = GLKMatrix4RotateZ(GLKMatrix4Identity, -M_PI_2);
			break;

		// Reverse portrait (upside down)
		case metaio::ESCREEN_ROTATION_90:
			// Rotate by 90° counter-clockwise
			m_modelViewProjectionMatrix = GLKMatrix4RotateZ(GLKMatrix4Identity, M_PI_2);
			break;

		// Landscape (right side of tall device facing up)
		case metaio::ESCREEN_ROTATION_0:
			m_modelViewProjectionMatrix = GLKMatrix4Identity;
			break;

		// Reverse landscape (left side of tall device facing up)
		case metaio::ESCREEN_ROTATION_180:
			// Rotate by 180°
			m_modelViewProjectionMatrix = GLKMatrix4RotateZ(GLKMatrix4Identity, M_PI);
			break;

		default:
			NSLog(@"Unknown screen rotation");
	}

	glUniformMatrix4fv(m_uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, m_modelViewProjectionMatrix.m);

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glDisableVertexAttribArray(ATTRIB_VERTEX);
	glDisableVertexAttribArray(ATTRIB_TEXCOORDS);

}

- (void)initialize:(int)cameraFrameWidth cameraFrameHeight:(int)cameraFrameHeight
{
#if !IOS_FAST_TEXTURE_UPLOAD

	m_textureWidth = getNextPowerOf2(cameraFrameWidth);
	m_textureHeight = getNextPowerOf2(cameraFrameHeight);

	m_pTextureBuffer = new uint8_t[cameraFrameWidth * cameraFrameHeight * 4];

	// Create texture
	glGenTextures(1, &m_texture);

#endif // !IOS_FAST_TEXTURE_UPLOAD

	// Create vertex buffer
	glGenVertexArraysOES(1, &m_vertexArray);
	glBindVertexArrayOES(m_vertexArray);

	glGenBuffers(1, &m_vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, m_vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(gVertexData), gVertexData, GL_STATIC_DRAW);

	// Create texture coordinates buffer
	glGenVertexArraysOES(1, &m_texCoordsArray);
	glBindVertexArrayOES(m_texCoordsArray);

	glGenBuffers(1, &m_texCoordsBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, m_texCoordsBuffer);

	glBindVertexArrayOES(0);

	[self loadShaders];

#if IOS_FAST_TEXTURE_UPLOAD
	
	EAGLContext *eaglContext = [EAGLContext currentContext];
	
	CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, eaglContext, NULL, &m_cvTextureCache);

	if (err != kCVReturnSuccess)
		NSLog(@"Failed to create Core Video texture cache");
	
#endif // IOS_FAST_TEXTURE_UPLOAD

	m_initialized = true;
}

- (float)scaleX
{
	return m_scaleX;
}

- (float)scaleY
{
	return m_scaleY;
}

- (void)updateFrame:(metaio::ImageStruct*)frame
{
#if IOS_FAST_TEXTURE_UPLOAD

	CVImageBufferRef imgBuffer = (CVImageBufferRef)frame->capturingContext;

	size_t frameWidth = CVPixelBufferGetWidth(imgBuffer);
	size_t frameHeight = CVPixelBufferGetHeight(imgBuffer);

	if (!m_initialized)
		[self initialize:frameWidth cameraFrameHeight:frameHeight];

	if (!m_cvTextureCache)
	{
		NSLog(@"Core Video texture cache not created, cannot upload texture");
		return;
	}

	// A new frame was captured, so release the previously cached texture since we won't use it
	// anymore
	if (m_cvTexture)
	{
		CFRelease(m_cvTexture);
		m_cvTexture = NULL;
	}

	// And instruct the cache to clean it up
	CVOpenGLESTextureCacheFlush(m_cvTextureCache, 0);

	// Create a texture from it
	CVOpenGLESTextureRef texture = NULL;
	CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
		kCFAllocatorDefault,
		m_cvTextureCache,
		imgBuffer,
		NULL,
		GL_TEXTURE_2D,
		GL_RGBA,
		frameWidth,
		frameHeight,
		GL_BGRA,
		GL_UNSIGNED_BYTE,
		0,
		&texture);

	if (err != kCVReturnSuccess)
		NSLog(@"Failed to create texture from CVImageBuffer");

	// Keep reference (already retained by the call above, so do not call CFRetain again)
	m_cvTexture = texture;
	m_lastCvTextureName = CVOpenGLESTextureGetName(texture);
	m_lastCvTextureTarget = CVOpenGLESTextureGetTarget(texture);

#else

	const int frameWidth = frame->width;
	const int frameHeight = frame->height;

	switch (frame->colorFormat)
	{
		case metaio::common::ECF_A8B8G8R8:
			if (!m_initialized)
				[self initialize:frameWidth cameraFrameHeight:frameHeight];

			if (!frame->originIsUpperLeft)
			{
				NSLog(@"Unimplemented: ABGR upside-down");
				return;
			}

			memcpy(m_pTextureBuffer, frame->buffer, frameWidth * frameHeight * 4);

			break;

		default:
			NSLog(@"Unimplemented color format");
			return;
	}

#endif // IOS_FAST_TEXTURE_UPLOAD

	m_mustUpdateTexture = true;

	m_cameraImageWidth = frameWidth;
	m_cameraImageHeight = frameHeight;
	m_cameraAspect = (float)frameWidth / frameHeight;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
	GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;

	// Create shader program.
	m_shaderProgram = glCreateProgram();

	// Create and compile vertex shader.
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"CameraImageShader" ofType:@"vsh"];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
	{
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}

	// Create and compile fragment shader.
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"CameraImageShader" ofType:@"fsh"];
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
	m_uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(m_shaderProgram, "modelViewProjectionMatrix");

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
	if (status == 0)
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
	if (status == 0)
		return NO;

	return YES;
}

@end
