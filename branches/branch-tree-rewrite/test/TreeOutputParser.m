#import "TreeOutputParser.h"
#import <ParseKit/ParseKit.h>

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self.assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self.assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface TreeOutputParser ()
@end

@implementation TreeOutputParser

- (id)init {
    self = [super init];
    if (self) {
        self.enableASTOutput = YES;

        self._tokenKindTab[@"baz"] = @(TREEOUTPUT_TOKEN_KIND_BAR);
        self._tokenKindTab[@"int"] = @(TREEOUTPUT_TOKEN_KIND_INT);
        self._tokenKindTab[@";"] = @(TREEOUTPUT_TOKEN_KIND_SEMI_COLON);

        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_BAR] = @"baz";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_INT] = @"int";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_SEMI_COLON] = @";";

    }
    return self;
}


- (PKAST *)_start {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"_start"];

    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        PKAST *foo_0 = [self foo]; 
        [ruleScope addAST:foo_0 forKey:@"foo"];

        ruleScope.tree = [ruleScope ASTForKey:@"foo"];
    } else if ([self predicts:TREEOUTPUT_TOKEN_KIND_BAR, 0]) {
        PKAST *bar_1 = [self bar]; 
        [ruleScope addAST:bar_1 forKey:@"bar"];

        ruleScope.tree = [ruleScope ASTForKey:@"bar"];
    } else if ([self predicts:TREEOUTPUT_TOKEN_KIND_INT, 0]) {
        PKAST *baz_2 = [self baz]; 
        [ruleScope addAST:baz_2 forKey:@"baz"];

        ruleScope.tree = [ruleScope ASTForKey:@"baz"];
    } else {
        [self raise:@"No viable alternative found in rule '_start'."];
    }
    [self matchEOF:YES]; 

    return ruleScope.tree;

}

- (PKAST *)foo {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"foo"];

    PKAST *Word_0 = [self matchWord:NO]; 
    [ruleScope addAST:Word_0 forKey:@"Word"];

    ruleScope.tree = [ruleScope ASTForKey:@"Word"];

    [self fireAssemblerSelector:@selector(parser:didMatchFoo:)];
    return ruleScope.tree;

}

- (PKAST *)bar {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"bar"];

    PKAST *lit_bar_0 = [self match:TREEOUTPUT_TOKEN_KIND_BAR discard:NO]; 
    [ruleScope addAST:lit_bar_0 forKey:@"'baz'"];

    ruleScope.tree = [ruleScope ASTForKey:@"'baz'"];

    [self fireAssemblerSelector:@selector(parser:didMatchBar:)];
    return ruleScope.tree;

}

- (PKAST *)baz {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"baz"];

    PKAST *lit_int_0 = [self match:TREEOUTPUT_TOKEN_KIND_INT discard:NO]; 
    [ruleScope addAST:lit_int_0 forKey:@"'int'"];
    PKAST *Word_1 = [self matchWord:NO]; 
    [ruleScope addAST:Word_1 forKey:@"Word"];
    PKAST *lit_semi_colon_2 = [self match:TREEOUTPUT_TOKEN_KIND_SEMI_COLON discard:NO]; 
    [ruleScope addAST:lit_semi_colon_2 forKey:@"';'"];

    ruleScope.tree = [ruleScope ASTForKey:@"'int'"];

    return ruleScope.tree;

}

@end