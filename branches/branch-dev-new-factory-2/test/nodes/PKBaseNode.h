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

@interface PKBaseNode : PKAST
- (void)visit:(id <PKNodeVisitor>)v;

@property (nonatomic, retain) NSString *parserName;
@property (nonatomic, retain) NSString *callbackName;

@property (nonatomic, assign) BOOL discard;
@end
