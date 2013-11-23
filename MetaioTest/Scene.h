#import <Foundation/Foundation.h>
#import <GLKit/GLKMatrix4.h>
#import <CoreMotion/CoreMotion.h>
#import <metaioSDK/IMetaioSDKIOS.h>

#ifndef __SCENE_H__
#define __SCENE_H__

#define OBJECT_COUNT 1

#define OBJECT_SNOWMAN 0

#define GLOOMIES_TARGET_TREE 0
#define GLOOMIES_TARGET_GIFT 1

#endif

@interface Scene : NSObject

- (void)setGloomiesTargetWithTrackingValues:(metaio::TrackingValues)trackingValues modelViewMatrix:(GLKMatrix4)modelViewMatrix deviceMotion:(CMDeviceMotion *)deviceMotion targetMode:(int)targetMode;
- (void)setGloomiesTargetWithDeviceMotion:(CMDeviceMotion *)deviceMotion;

- (void)update:(CMDeviceMotion *)deviceMotion;

- (void)drawTreeGloomiesWithModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawObject:(int)objectIndex withModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix;

- (void)drawGloomies:(CMDeviceMotion *)deviceMotion projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawSnow:(CMDeviceMotion *)deviceMotion projectionMatrix:(GLKMatrix4)projectionMatrix;

@property (nonatomic) float cameraAlpha;

@end
