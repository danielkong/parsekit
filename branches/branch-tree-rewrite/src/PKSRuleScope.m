//
//  PKSRuleScope.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import "PKSRuleScope.h"
#import <ParseKit/PKAST.h>
#import "PKSTreeAdaptor.h"

@interface PKSRuleScope ()
@property (nonatomic, retain) NSMutableDictionary *tab;
@end

@implementation PKSRuleScope

+ (PKSRuleScope *)ruleScopeWithTreeAdaptor:(PKSTreeAdaptor *)ator {
    return [[[self alloc] initWithTreeAdaptor:ator] autorelease];
}


- (id)initWithTreeAdaptor:(PKSTreeAdaptor *)ator {
    NSParameterAssert(ator);
    
    self = [super init];
    if (self) {
        self.tab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.tree = nil;
    self.adaptor = nil;
    self.tab = nil;
    [super dealloc];
}


- (void)addAST:(PKAST *)tree forKey:(NSString *)key {
    NSParameterAssert(tree);
    NSParameterAssert([key length]);
    NSAssert(_tab, @"");
    
    NSMutableArray *all = _tab[key];
    if (!all) {
        all = [NSMutableArray array];
        _tab[key] = all;
    }
    
    [all addObject:tree];
}


- (NSArray *)allForKey:(NSString *)key {
    NSParameterAssert([key length]);
    NSAssert(_tab, @"");
    
    NSArray *all = _tab[key];
    NSAssert(all, @"");
    
    return all;
}


- (NSUInteger)cardinalityForKey:(NSString *)key {
    NSUInteger c = [[self allForKey:key] count];
    return c;
}


- (PKAST *)ASTForKey:(NSString *)key {
    NSArray *all = [self allForKey:key];
    NSAssert(1 == [all count], @"");
    
    PKAST *tree = all[0];
    return tree;
}


- (PKAST *)tree {
    if (!_tree) {
        self.tree = [[self.adaptor newTreeWithToken:nil] autorelease];
    }
    return _tree;
}

@end
