//
//  PKReferencePhaseVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBaseVisitor.h"

@class PKCompositeParser;

@interface PKResolutionPhaseVisitor : PKBaseVisitor

@property (nonatomic, retain) PKCompositeParser *currentParser;
@end
