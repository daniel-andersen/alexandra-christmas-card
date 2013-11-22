#import <Foundation/Foundation.h>
#include <metaioSDK/IMetaioSDK.h>

// Set this to true if you want to exploit fast texture upload using CVOpenGLESTextureCache and the
// capturing context (a CVImageBufferRef object) exposed by the metaio SDK. This is specific to iOS.
#define IOS_FAST_TEXTURE_UPLOAD false

@interface CameraImageRenderer : NSObject
{
	/**
	 * Camera frame aspect ratio (does not change with screen rotation, e.g. 640/480 = 1.333)
	 */
	float		m_cameraAspect;

	int			m_cameraImageWidth;
	int			m_cameraImageHeight;
	bool		m_initialized;
	bool		m_mustUpdateTexture;

	/**
	 * Value by which the X axis must be scaled in the overall projection matrix in order to make
	 * up for a aspect-corrected (by cropping) camera image. Set on each draw() call.
	 */
	float		m_scaleX;
	
	float		m_scaleY;

	GLuint		m_shaderProgram;
	GLuint		m_texCoordsArray;
	GLuint		m_texCoordsBuffer;
	GLuint		m_vertexArray;
	GLuint		m_vertexBuffer;

#if IOS_FAST_TEXTURE_UPLOAD

	/**
	 * Reference to the previously captured and cached texture. Released whenever a new frame is
	 * captured by the camera.
	 */
	CVOpenGLESTextureRef		m_cvTexture;

	/**
	 * Automatically takes care of creating enough textures for cached textures of the captured
	 * camera images.
	 */
	CVOpenGLESTextureCacheRef	m_cvTextureCache;

	/**
	 * OpenGL texture identifier associated with m_cvTexture.
	 */
	GLuint						m_lastCvTextureName;

	/**
	 * Always GL_TEXTURE_2D because the camera image is 2D.
	 */
	GLenum						m_lastCvTextureTarget;

#else
	
	GLuint		m_texture;
	uint8_t*	m_pTextureBuffer;
	int			m_textureWidth;
	int			m_textureHeight;
	bool		m_textureInitialized;

#endif
}

- (void)draw:(metaio::ESCREEN_ROTATION)screenRotation renderTargetAspect:(float)screenAspect;
- (float)scaleX;
- (float)scaleY;
- (void)updateFrame:(metaio::ImageStruct*)frame;

@end
