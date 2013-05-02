//
//  PKSRuleScope.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import <Foundation/Foundation.h>

@class PKAST;
@class PKSTreeAdaptor;

@interface PKSRuleScope : NSObject

+ (PKSRuleScope *)ruleScopeWithTreeAdaptor:(PKSTreeAdaptor *)ator;

- (id)initWithTreeAdaptor:(PKSTreeAdaptor *)ator;

- (void)addAST:(PKAST *)tree forKey:(NSString *)key;
- (NSArray *)allForKey:(NSString *)key;
- (NSUInteger)cardinalityForKey:(NSString *)key;

// convenience
- (PKAST *)ASTForKey:(NSString *)key;

@property (nonatomic, retain) PKAST *tree;
@property (nonatomic, retain) PKSTreeAdaptor *adaptor;
@end
