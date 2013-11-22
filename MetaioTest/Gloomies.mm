//
//  Gloomies.m
//  MetaioTest
//
//  Created by Daniel Andersen on 06/11/13.
//  Copyright (c) 2013 Alexandra Instituttet. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "Gloomies.h"
#import "Constants.h"

@interface Gloomies ()

@property (nonatomic) bool arrivedAtTarget;

@property (nonatomic) GLKVector3 *outputVertices;
@property (nonatomic) GLKVector2 *outputTexCoords;

@end

@implementation Gloomies

@synthesize individualsCount;
@synthesize individuals;

@synthesize targetPosition;
@synthesize averagePosition;
@synthesize averageVelocity;

@synthesize outputVertices;
@synthesize outputTexCoords;

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self initializeIndividuals];
    [self initializeFlock];
}

- (void)dealloc {
	for (int i = 0; i < individualsCount; i++) {
		delete individuals[i];
	}
	delete individuals;
    
	delete outputVertices;
	delete outputTexCoords;
}

- (void)initializeIndividuals {
    individualsCount = [Constants instance].gloomiesCount;
    
	individuals = new Gloomie*[individualsCount];
    
	for (int i = 0; i < individualsCount; i++) {
		individuals[i] = new Gloomie;
        
		individuals[i]->position.x = (((float)rand() / (float)RAND_MAX) * 500.0f) - 250.0f;
		individuals[i]->position.y = (((float)rand() / (float)RAND_MAX) * 500.0f) - 250.0f;
		individuals[i]->position.z = (((float)rand() / (float)RAND_MAX) * 500.0f) - 250.0f;
        
		individuals[i]->velocity.x = 0.0f;
		individuals[i]->velocity.y = 0.0f;
		individuals[i]->velocity.z = 0.0f;
        
		individuals[i]->unitVelocity.x = 0.0f;
		individuals[i]->unitVelocity.y = 0.0f;
		individuals[i]->unitVelocity.z = 0.0f;
        
		individuals[i]->destVelocity.x = 0.0f;
		individuals[i]->destVelocity.y = 0.0f;
		individuals[i]->destVelocity.z = 0.0f;
        
		individuals[i]->targetDist = 0.0f;
		individuals[i]->velocityRangeIndex = 0.0f;
	}
}

- (void)initializeFlock {
	targetPosition.x = 0.0f;
	targetPosition.y = 0.0f;
	targetPosition.z = 0.0f;
    
	self.arrivedAtTarget = NO;
    
	[self calculateAveragePosition];
	[self calculateAverageVelocity];
}

- (void)calculateAveragePosition {
	averagePosition.x = 0.0f;
	averagePosition.y = 0.0f;
	averagePosition.z = 0.0f;
    
	for (int i = individualsCount - 1; i >= 0; i--) {
		averagePosition.x += individuals[i]->position.x;
		averagePosition.y += individuals[i]->position.y;
		averagePosition.z += individuals[i]->position.z;
	}
}

- (void)calculateAverageVelocity {
	averageVelocity.x = 0.0f;
	averageVelocity.y = 0.0f;
	averageVelocity.z = 0.0f;
    
	for (int i = individualsCount - 1; i >= 0; i--) {
		averageVelocity.x += individuals[i]->velocity.x;
		averageVelocity.y += individuals[i]->velocity.y;
		averageVelocity.z += individuals[i]->velocity.z;
	}
}

-(void)calculateDistanceToTarget {
	for (int i = individualsCount - 1; i >= 0; i--) {
		GLKVector3 delta;
		delta.x = individuals[i]->position.x - targetPosition.x;
		delta.y = individuals[i]->position.y - targetPosition.y;
		delta.z = individuals[i]->position.z - targetPosition.z;
        
		individuals[i]->targetDist = sqrt((delta.x * delta.x) +
                                          (delta.y * delta.y) +
                                          (delta.z * delta.z));
	}
}

-(void)sortDistanceToTarget {
	for (int i = individualsCount - 1; i >= 1; i--) {
		if (individuals[i - 1]->targetDist > individuals[i]->targetDist) {
            Gloomie *tmp = individuals[i];
            individuals[i] = individuals[i - 1];
            individuals[i - 1] = tmp;
        }
	}
}

- (void)calculateDestinationVelocity {
	for (int i = individualsCount - 1; i >= 0; i--) {
		Gloomie *individual = individuals[i];
        
		// Target
		GLKVector3 velTarget = GLKVector3Make(targetPosition.x - individual->position.x,
                                              targetPosition.y - individual->position.y,
                                              targetPosition.z - individual->position.z);
        
		float lenTarget = individual->targetDist;
        
		if (lenTarget > 0.0f) {
			velTarget.x /= lenTarget;
			velTarget.y /= lenTarget;
			velTarget.z /= lenTarget;
		}
        
		// Leader
		GLKVector3 velLeader;

		if (i >= 2) {
			velLeader.x = individuals[i - 2]->position.x - (individuals[i - 2]->unitVelocity.x * [Constants instance].gloomiesSeparationDistance);
			velLeader.y = individuals[i - 2]->position.y - (individuals[i - 2]->unitVelocity.y * [Constants instance].gloomiesSeparationDistance);
			velLeader.z = individuals[i - 2]->position.z - (individuals[i - 2]->unitVelocity.z * [Constants instance].gloomiesSeparationDistance);
		} else {
			velLeader.x = targetPosition.x;
			velLeader.y = targetPosition.y;
			velLeader.z = targetPosition.z;
		}
        
		velLeader.x -= individual->position.x;
		velLeader.y -= individual->position.y;
		velLeader.z -= individual->position.z;
        
		float lenLeader = sqrt((velLeader.x * velLeader.x) +
                               (velLeader.y * velLeader.y) +
                               (velLeader.z * velLeader.z));
        
		if (lenLeader > 0.0f) {
			velLeader.x /= lenLeader;
			velLeader.y /= lenLeader;
			velLeader.z /= lenLeader;
		}
        
		// Calculate velocity change range - 1-sqr(1-len)
		individual->velocityRangeIndex = 1.0f - MIN(1.0f, individual->targetDist / [Constants instance].gloomiesMaxDistanceToTarget);
		individual->velocityRangeIndex = 1.0f - (individual->velocityRangeIndex * individual->velocityRangeIndex);
        
		float changeMax = [Constants instance].gloomiesVelocityChangeRangeMin + (([Constants instance].gloomiesVelocityChangeRangeMax - [Constants instance].gloomiesVelocityChangeRangeMin) * individual->velocityRangeIndex);
        
		// Sum velocities
		individual->destVelocity.x = ((velTarget.x + velLeader.x) * changeMax) / 2.0f;
		individual->destVelocity.y = ((velTarget.y + velLeader.y) * changeMax) / 2.0f;
		individual->destVelocity.z = ((velTarget.z + velLeader.z) * changeMax) / 2.0f;
	}
}

- (void)moveIndividuals {
    
	// Reset average position
	averagePosition.x = 0.0f;
	averagePosition.y = 0.0f;
	averagePosition.z = 0.0f;
    
	// Reset average velocity
	averageVelocity.x = 0.0f;
	averageVelocity.y = 0.0f;
	averageVelocity.z = 0.0f;

	// Update velocity and move individuals
	for (int i = individualsCount - 1; i >= 0; i--) {
        
		Gloomie *individual = individuals[i];
        
		// Update velocity
		individual->velocity.x += individual->destVelocity.x;
		individual->velocity.y += individual->destVelocity.y;
		individual->velocity.z += individual->destVelocity.z;
        
		// Normalize velocity
		float len = sqrt((individual->velocity.x * individual->velocity.x) +
                         (individual->velocity.y * individual->velocity.y) +
                         (individual->velocity.z * individual->velocity.z));
        
		if (len > 0.0f) {
			individual->unitVelocity.x = individual->velocity.x / len;
			individual->unitVelocity.y = individual->velocity.y / len;
			individual->unitVelocity.z = individual->velocity.z / len;
		}
        
		float changeMax = [Constants instance].gloomiesVelocityRangeMin + (([Constants instance].gloomiesVelocityRangeMax - [Constants instance].gloomiesVelocityRangeMin) * individual->velocityRangeIndex);
        
		if (len > changeMax) {
			individual->velocity.x = individual->unitVelocity.x * changeMax;
			individual->velocity.y = individual->unitVelocity.y * changeMax;
			individual->velocity.z = individual->unitVelocity.z * changeMax;
		}
        
		// Move individual
		individual->position.x += individual->velocity.x;
		individual->position.y += individual->velocity.y;
		individual->position.z += individual->velocity.z;
        
		// Add to average
		averagePosition.x += individual->position.x;
		averagePosition.y += individual->position.y;
		averagePosition.z += individual->position.z;
        
		// Add velocity to average
		averageVelocity.x += individual->velocity.x;
		averageVelocity.y += individual->velocity.y;
		averageVelocity.z += individual->velocity.z;
	}
    
	// Calculate average position
	averagePosition.x /= individualsCount;
	averagePosition.y /= individualsCount;
	averagePosition.z /= individualsCount;
    
	// Calculate average velocity
	float velocityLength = sqrt((averageVelocity.x * averageVelocity.x) +
                                (averageVelocity.y * averageVelocity.y) +
                                (averageVelocity.z * averageVelocity.z));
    
	if (velocityLength > 0.0f) {
		averageVelocity.x /= velocityLength;
		averageVelocity.y /= velocityLength;
		averageVelocity.z /= velocityLength;
	}
}

- (void)moveTargetInDir:(GLKVector3)v {
	targetPosition.x += v.x;
	targetPosition.y += v.y;
	targetPosition.z += v.z;
}

- (void)update {
	[self calculateDistanceToTarget];
	[self sortDistanceToTarget];
	[self calculateDestinationVelocity];
	[self moveIndividuals];
}

- (void)render {
	//glTranslatef(0.0f, 0.0f, -1.0f);
    
	// Calculate vertices
	int index = 0;

	for (int i = individualsCount - 1; i >= 0; i--) {
		outputVertices[index  ].x = individuals[i]->position.x + ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index  ].y = individuals[i]->position.y - ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index++].z = individuals[i]->position.z - ([Constants instance].gloomiesRenderSize / 2.0f);
        
		outputVertices[index  ].x = individuals[i]->position.x - ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index  ].y = individuals[i]->position.y - ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index++].z = individuals[i]->position.z - ([Constants instance].gloomiesRenderSize / 2.0f);
        
		outputVertices[index  ].x = individuals[i]->position.x + ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index  ].y = individuals[i]->position.y + ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index++].z = individuals[i]->position.z - ([Constants instance].gloomiesRenderSize / 2.0f);
        
		outputVertices[index  ].x = individuals[i]->position.x + ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index  ].y = individuals[i]->position.y + ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index++].z = individuals[i]->position.z - ([Constants instance].gloomiesRenderSize / 2.0f);

		outputVertices[index  ].x = individuals[i]->position.x - ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index  ].y = individuals[i]->position.y - ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index++].z = individuals[i]->position.z - ([Constants instance].gloomiesRenderSize / 2.0f);

		outputVertices[index  ].x = individuals[i]->position.x - ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index  ].y = individuals[i]->position.y + ([Constants instance].gloomiesRenderSize / 2.0f);
		outputVertices[index++].z = individuals[i]->position.z - ([Constants instance].gloomiesRenderSize / 2.0f);
	}
    
	// Render
    //glDisable(GL_ALPHA_TEST);
    
	//glEnable(GL_TEXTURE_2D);
	//glBindTexture(GL_TEXTURE_2D, gloomieTexture->index);
    
	//glEnable(GL_BLEND);
	//glBlendFunc(GL_ONE, GL_ONE);
    
	//glDepthMask(GL_FALSE);
    
	//glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    
    //glEnableClientState(GL_VERTEX_ARRAY);
    //glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    //glVertexPointer(3, GL_FLOAT, 0, outputVertices);
	//glTexCoordPointer(2, GL_FLOAT, 0, outputTexCoords);
    
	//glDrawArrays(GL_TRIANGLES, 0, individualsCount * 6);
    
	//glDepthMask(GL_TRUE);
    
	//glDisable(GL_TEXTURE_2D);
	//glDisable(GL_BLEND);
    
    //glDisableClientState(GL_VERTEX_ARRAY);
    //glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
	//glEnable(GL_ALPHA_TEST);
}


@end
