//
//  PKSRuleScope.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import "PKSRuleScope.h"
#import <ParseKit/PKAST.h>
#import <ParseKit/PKToken.h>
#import "PKSTreeAdaptor.h"

@interface PKSRuleScope ()
@property (nonatomic, retain) NSMutableDictionary *tab;
@property (nonatomic, retain) NSMutableDictionary *addCountTab;
@end

@implementation PKSRuleScope

+ (PKSRuleScope *)ruleScopeWithName:(NSString *)name {
    return [[[self alloc] initWithName:name] autorelease];
}


- (id)initWithName:(NSString *)name {
    NSParameterAssert([name length]);
    
    self = [super init];
    if (self) {
        self.name = name;
        self.tab = [NSMutableDictionary dictionary];
        self.addCountTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.tree = nil;
    self.tab = nil;
    self.addCountTab = nil;
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
        _addCountTab[key] = (id)kCFBooleanFalse;
    }
    
    [all addObject:tree];
}


- (NSArray *)allForKey:(NSString *)key {
    NSParameterAssert([key length]);
    NSAssert(_tab, @"");
    
    NSArray *all = _tab[key];
    
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



- (void)addChild:(PKAST *)child toParent:(PKAST *)parent {
    NSString *key = child.token.stringValue;

    NSAssert(key, @"");
    if (key) {
        BOOL needsCopy = [_addCountTab[key] boolValue];
        _addCountTab[key] = (id)kCFBooleanTrue;
        
        if (needsCopy) {
            child = [[child copy] autorelease];
        }
    }
    
    [parent addChild:child];
}


- (void)setTree:(PKAST *)tree {
    if (tree != _tree) {
        NSString *key = tree.token.stringValue;
        
        if (key) {
            BOOL needsCopy = [_addCountTab[key] boolValue];
            _addCountTab[key] = (id)kCFBooleanTrue;
            
            if (needsCopy) {
                tree = [[tree copy] autorelease];
            }
        }
        
        [_tree autorelease];
        _tree = [tree retain];
        
        if (_tree) {
            [self addAST:_tree forKey:_name];
        }
    }
}

@end
