//
//  PKNode.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"
#import "PKAST.h"
#import "PKConstructNodeVisitor.h"

@interface PKNodeBase : PKAST
- (void)visit:(id <PKNodeVisitor>)v;

@property (nonatomic, assign) BOOL discard;
@end
