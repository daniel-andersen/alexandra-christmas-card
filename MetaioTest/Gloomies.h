//
//  Gloomies.h
//  MetaioTest
//
//  Created by Daniel Andersen on 06/11/13.
//  Copyright (c) 2013 Alexandra Instituttet. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    GLKVector3 position;
	GLKVector3 velocity;
	GLKVector3 unitVelocity;
	GLKVector3 destVelocity;
    GLKVector3 targetPosition;
    float randomSpeed;
	float targetDist;
	float velocityRangeIndex;
} Gloomie;


@interface Gloomies : NSObject

- (void)update;

@property (nonatomic) int individualsCount;
@property (nonatomic) Gloomie **individuals;

@property (nonatomic) bool individualTargets;

@property (nonatomic) GLKVector3 targetPosition;
@property (nonatomic) GLKVector3 averagePosition;
@property (nonatomic) GLKVector3 averageVelocity;

@end
