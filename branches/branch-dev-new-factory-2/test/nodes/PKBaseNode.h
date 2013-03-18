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

//@protocol PKNodeVisitor;

@interface PKBaseNode : PKAST
+ (id)nodeWithToken:(PKToken *)tok;

- (void)visit:(id <PKNodeVisitor>)v;

- (void)replaceChild:(PKBaseNode *)oldChild withChild:(PKBaseNode *)newChild;

@property (nonatomic, assign) BOOL discard;
@property (nonatomic, retain) Class parserClass;
@end
