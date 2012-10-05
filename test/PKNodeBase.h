//
//  PKNode.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"
#import "PKAST.h"
#import "PKParserVisitor.h"

@interface PKNodeBase : PKAST
- (void)visit:(PKParserVisitor *)v;

@property (nonatomic, assign) BOOL discard;
@end
