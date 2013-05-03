//
//  PKSRuleScope.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import <Foundation/Foundation.h>

@class PKAST;

@interface PKSRuleScope : NSObject

+ (PKSRuleScope *)ruleScopeWithName:(NSString *)name;

- (id)initWithName:(NSString *)name;

- (void)addAST:(PKAST *)tree forKey:(NSString *)key;
- (NSArray *)allForKey:(NSString *)key;
- (NSUInteger)cardinalityForKey:(NSString *)key;

// convenience
- (PKAST *)ASTForKey:(NSString *)key;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) PKAST *tree;
@end
