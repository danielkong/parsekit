//
//  PKNode.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKNodeTypes.h"
#import "PKAST.h"
#import "PKNodeVisitor.h" // convenience

@class PKCompositeParser;
//@protocol PKNodeVisitor;

@interface PKBaseNode : PKAST
+ (id)nodeWithToken:(PKToken *)tok;

- (void)visit:(id <PKNodeVisitor>)v;

- (void)replaceChild:(PKBaseNode *)oldChild withChild:(PKBaseNode *)newChild;
- (void)replaceChild:(PKBaseNode *)oldChild withChildren:(NSArray *)newChildren;

@property (nonatomic, assign) BOOL discard;
@property (nonatomic, retain) Class parserClass;
@property (nonatomic, retain) PKCompositeParser *parser;
@end
