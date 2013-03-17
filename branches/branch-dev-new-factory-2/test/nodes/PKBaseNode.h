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
@class PKBaseSymbol;

@interface PKBaseNode : PKAST
+ (id)nodeWithToken:(PKToken *)tok;

- (void)visit:(id <PKNodeVisitor>)v;

@property (nonatomic, assign) BOOL discard;
@property (nonatomic, retain) Class parserClass;
@property (nonatomic, retain) PKBaseSymbol *symbol;
@end
