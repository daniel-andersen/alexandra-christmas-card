#import <Foundation/Foundation.h>
#import <GLKit/GLKMatrix4.h>
#import <CoreMotion/CoreMotion.h>
#import <metaioSDK/IMetaioSDKIOS.h>

#ifndef __SCENE_H__
#define __SCENE_H__

#define OBJECT_COUNT 1
#define giftCount 4

#define OBJECT_SNOWMAN 0

#define GLOOMIES_TARGET_NONE  0
#define GLOOMIES_TARGET_TREE  1
#define GLOOMIES_TARGET_GIFT  2
#define GLOOMIES_TARGET_ARROW 3
#define GLOOMIES_TARGET_SEEKING_OBJECT 4
#define GLOOMIES_TARGET_VIEWING_OBJECT 5
#define GLOOMIES_TARGET_BRINGING_OBJECT_HOME 6
#define GLOOMIES_TARGET_PLACE_OBJECT 7

#define VIEWING_TREE_TIME 10.0f
#define VIEWING_GIFT_TIME 4.0f
#define VIEWING_ARROW_TIME 10.0f
#define SEEKING_OBJECT_DELAY 3.0f
#define SEEKING_OBJECT_TIMEOUT 30.0f

#endif

@interface Scene : NSObject

- (void)setGloomiesTargetWithTrackingValues:(metaio::TrackingValues)trackingValues modelViewMatrix:(GLKMatrix4)modelViewMatrix deviceMotion:(CMDeviceMotion *)deviceMotion targetMode:(int)targetMode;
- (void)setGloomiesTargetWithDeviceMotion:(CMDeviceMotion *)deviceMotion targetMode:(int)targetMode;

- (void)startShowingArrow;
- (void)startShowingGift;
- (void)startViewingObject;

- (float)gloomiesDistanceToTarget;

- (void)randomGloomiesDestinationAwayFromCamera;

- (void)update:(CMDeviceMotion *)deviceMotion;

- (void)drawTreeGloomiesWithModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawObject:(int)objectIndex withModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawInfoWithProjectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawGift:(int)index withModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawGiftWithModelViewMatrix:(GLKMatrix4)modelViewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawGiftWithProjectionMatrix:(GLKMatrix4)projectionMatrix;

- (void)drawGloomies:(CMDeviceMotion *)deviceMotion projectionMatrix:(GLKMatrix4)projectionMatrix;
- (void)drawSnow:(CMDeviceMotion *)deviceMotion projectionMatrix:(GLKMatrix4)projectionMatrix;

@property (nonatomic) float cameraAlpha;
@property (nonatomic) float distanceToTrackedObject;
@property (nonatomic) int giftNumber;

@end
