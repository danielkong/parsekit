//
//  PKNodeReference.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"

@protocol PKScope;

@interface PKReferenceNode : PKBaseNode

@property (nonatomic, retain) id <PKScope>scope;
@end
