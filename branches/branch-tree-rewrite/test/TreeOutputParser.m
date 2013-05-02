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



    }
    return self;
}


- (PKAST *)_start {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithTreeAdaptor:self.adaptor];
    [self foo]; 
    [self matchEOF:YES]; 

    return ruleScope.tree;

}

- (PKAST *)foo {
    
    PKSRuleScope *ruleScope = [PKSRuleScope ruleScopeWithTreeAdaptor:self.adaptor];
    PKAST *Word_0 = [self matchWord:NO]; 
    [ruleScope addAST:Word_0 forKey:@"Word"];

    [self fireAssemblerSelector:@selector(parser:didMatchFoo:)];
    return ruleScope.tree;

}

@end