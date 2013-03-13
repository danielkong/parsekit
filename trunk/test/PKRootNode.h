//
//  PKRootNode.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"
#import "PKAST.h"
#import "PKNodeVisitor.h"

@interface PKRootNode : PKAST
- (void)visit:(PKNodeVisitor *)v;

@end
