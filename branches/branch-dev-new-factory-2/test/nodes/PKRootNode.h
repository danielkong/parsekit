//
//  PKRootNode.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"

@interface PKRootNode : PKBaseNode
- (void)visit:(id <PKNodeVisitor>)v;

@end
