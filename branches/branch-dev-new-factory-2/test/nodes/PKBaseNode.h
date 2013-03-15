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
+ (id)nodeWithToken:(PKToken *)tok;
+ (id)nodeWithToken:(PKToken *)tok parserName:(NSString *)pname;
+ (id)nodeWithToken:(PKToken *)tok parserName:(NSString *)pname callbackName:(NSString *)cbname;

- (id)initWithToken:(PKToken *)tok parserName:(NSString *)pname;
- (id)initWithToken:(PKToken *)tok parserName:(NSString *)pname callbackName:(NSString *)cbname;

- (void)visit:(id <PKNodeVisitor>)v;

@property (nonatomic, retain, readonly) NSString *parserName;
@property (nonatomic, retain, readonly) NSString *callbackName;

@property (nonatomic, assign) BOOL discard;
@end
