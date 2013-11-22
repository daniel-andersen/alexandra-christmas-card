//
//  Constants.h
//  MetaioTest
//
//  Created by Daniel Andersen on 06/11/13.
//  Copyright (c) 2013 Alexandra Instituttet. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef __CONSTANTS__
#define __CONSTANTS__

#define BUFFER_OFFSET(i) ((uint8_t *)NULL + (i))

#define NUM_TRACKABLE_OBJECTS 3

typedef struct {
    float position[3];
    float texCoord[2];
} Vertex;

#endif

@interface Constants : NSObject

+ (Constants *)instance;

@property (nonatomic) int gloomiesCount;

@property (nonatomic) float gloomiesRenderSize;

@property (nonatomic) float gloomiesSeparationDistance;
@property (nonatomic) float gloomiesMaxDistanceToTarget;
@property (nonatomic) float gloomiesVelocityChangeRangeMin;
@property (nonatomic) float gloomiesVelocityChangeRangeMax;
@property (nonatomic) float gloomiesVelocityRangeMin;
@property (nonatomic) float gloomiesVelocityRangeMax;

@end
