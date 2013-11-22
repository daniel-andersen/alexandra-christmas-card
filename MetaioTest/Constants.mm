//
//  Constants.m
//  MetaioTest
//
//  Created by Daniel Andersen on 06/11/13.
//  Copyright (c) 2013 Alexandra Instituttet. All rights reserved.
//

#import "Constants.h"

Constants *constantsInstance = nil;

@implementation Constants

+ (Constants *)instance {
    @synchronized (self) {
        if (constantsInstance == nil) {
            constantsInstance = [[Constants alloc] init];
        }
        return constantsInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.gloomiesCount = 64;

    self.gloomiesRenderSize = 0.2f;
    
    self.gloomiesSeparationDistance = 50.0f;
    self.gloomiesMaxDistanceToTarget = 500.0f;
    self.gloomiesVelocityChangeRangeMin = 0.001f * 150.0f;
    self.gloomiesVelocityChangeRangeMax = 0.005f * 150.0f;
    self.gloomiesVelocityRangeMin = 0.05f * 40.0f;
    self.gloomiesVelocityRangeMax = 0.3f * 40.0f;
}

@end
