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

        self._tokenKindTab[@"]"] = @(TREEOUTPUT_TOKEN_KIND_CLOSE_BRACKET);
        self._tokenKindTab[@"["] = @(TREEOUTPUT_TOKEN_KIND_OPEN_BRACKET);
        self._tokenKindTab[@"array"] = @(TREEOUTPUT_TOKEN_KIND_ARRAY);
        self._tokenKindTab[@"int"] = @(TREEOUTPUT_TOKEN_KIND_INT);
        self._tokenKindTab[@"baz"] = @(TREEOUTPUT_TOKEN_KIND_BAR);
        self._tokenKindTab[@";"] = @(TREEOUTPUT_TOKEN_KIND_SEMI_COLON);

        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_CLOSE_BRACKET] = @"]";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_OPEN_BRACKET] = @"[";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_ARRAY] = @"array";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_INT] = @"int";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_BAR] = @"baz";
        self._tokenKindNameTab[TREEOUTPUT_TOKEN_KIND_SEMI_COLON] = @";";

    }
    return self;
}


- (PKAST *)_start {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"_start"];

    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        PKAST *foo_0 = [self foo]; 
        [ruleScope addAST:foo_0 forKey:@"foo"];

        PKAST *_parent = [ruleScope ASTForKey:@"foo"];
        ruleScope.tree = _parent;
    } else if ([self predicts:TREEOUTPUT_TOKEN_KIND_BAR, 0]) {
        PKAST *bar_1 = [self bar]; 
        [ruleScope addAST:bar_1 forKey:@"bar"];

        PKAST *_parent = [ruleScope ASTForKey:@"bar"];
        ruleScope.tree = _parent;
    } else if ([self predicts:TREEOUTPUT_TOKEN_KIND_INT, 0]) {
        PKAST *baz_2 = [self baz]; 
        [ruleScope addAST:baz_2 forKey:@"baz"];

        PKAST *_parent = [ruleScope ASTForKey:@"baz"];
        ruleScope.tree = _parent;
    } else if ([self predicts:TREEOUTPUT_TOKEN_KIND_ARRAY, 0]) {
        PKAST *bat_3 = [self bat]; 
        [ruleScope addAST:bat_3 forKey:@"bat"];

        PKAST *_parent = [ruleScope ASTForKey:@"bat"];
        ruleScope.tree = _parent;
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

    PKAST *_parent = [ruleScope ASTForKey:@"Word"];
    ruleScope.tree = _parent;

    [self fireAssemblerSelector:@selector(parser:didMatchFoo:)];
    return ruleScope.tree;

}

- (PKAST *)bar {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"bar"];

    PKAST *lit_bar_0 = [self match:TREEOUTPUT_TOKEN_KIND_BAR discard:NO]; 
    [ruleScope addAST:lit_bar_0 forKey:@"'baz'"];

    PKAST *_parent = [ruleScope ASTForKey:@"'baz'"];
    ruleScope.tree = _parent;

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

    PKAST *_parent = [ruleScope ASTForKey:@"'int'"];
    ruleScope.tree = _parent;
    [_parent addChild:[ruleScope ASTForKey:@"Word"]];

    return ruleScope.tree;

}

- (PKAST *)bat {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"bat"];

    PKAST *array_0 = [self array]; 
    [ruleScope addAST:array_0 forKey:@"array"];
    PKAST *lit_open_bracket_1 = [self match:TREEOUTPUT_TOKEN_KIND_OPEN_BRACKET discard:NO]; 
    [ruleScope addAST:lit_open_bracket_1 forKey:@"'['"];
    PKAST *Number_2 = [self matchNumber:NO]; 
    [ruleScope addAST:Number_2 forKey:@"Number"];
    PKAST *lit_close_bracket_3 = [self match:TREEOUTPUT_TOKEN_KIND_CLOSE_BRACKET discard:NO]; 
    [ruleScope addAST:lit_close_bracket_3 forKey:@"']'"];
    PKAST *lit_semi_colon_4 = [self match:TREEOUTPUT_TOKEN_KIND_SEMI_COLON discard:NO]; 
    [ruleScope addAST:lit_semi_colon_4 forKey:@"';'"];

    PKAST *_parent = [ruleScope ASTForKey:@"array"];
    ruleScope.tree = _parent;
    [_parent addChild:[ruleScope ASTForKey:@"'['"]];
    _parent = [ruleScope ASTForKey:@"'['"];
    [_parent addChild:[ruleScope ASTForKey:@"Number"]];

    return ruleScope.tree;

}

- (PKAST *)array {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithName:@"array"];

    PKAST *lit_array_0 = [self match:TREEOUTPUT_TOKEN_KIND_ARRAY discard:NO]; 
    [ruleScope addAST:lit_array_0 forKey:@"'array'"];

    PKAST *_parent = [ruleScope ASTForKey:@"'array'"];
    ruleScope.tree = _parent;

    [self fireAssemblerSelector:@selector(parser:didMatchArray:)];
    return ruleScope.tree;

}

@end