#import "ElementAssignParser.h"
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

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface ElementAssignParser ()
@property (nonatomic, retain) NSMutableDictionary *stat_memo;
@property (nonatomic, retain) NSMutableDictionary *assign_memo;
@property (nonatomic, retain) NSMutableDictionary *list_memo;
@property (nonatomic, retain) NSMutableDictionary *elements_memo;
@property (nonatomic, retain) NSMutableDictionary *element_memo;
@property (nonatomic, retain) NSMutableDictionary *lbracket_memo;
@property (nonatomic, retain) NSMutableDictionary *rbracket_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *eq_memo;
@property (nonatomic, retain) NSMutableDictionary *dot_memo;
@property (nonatomic, retain) NSMutableDictionary *semi_memo;
@end

@implementation ElementAssignParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"]"] = @(ELEMENTASSIGN_TOKEN_KIND_RBRACKET);
        self._tokenKindTab[@"["] = @(ELEMENTASSIGN_TOKEN_KIND_LBRACKET);
        self._tokenKindTab[@","] = @(ELEMENTASSIGN_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"="] = @(ELEMENTASSIGN_TOKEN_KIND_EQ);
        self._tokenKindTab[@";"] = @(ELEMENTASSIGN_TOKEN_KIND_SEMI);
        self._tokenKindTab[@"."] = @(ELEMENTASSIGN_TOKEN_KIND_DOT);

        self.stat_memo = [NSMutableDictionary dictionary];
        self.assign_memo = [NSMutableDictionary dictionary];
        self.list_memo = [NSMutableDictionary dictionary];
        self.elements_memo = [NSMutableDictionary dictionary];
        self.element_memo = [NSMutableDictionary dictionary];
        self.lbracket_memo = [NSMutableDictionary dictionary];
        self.rbracket_memo = [NSMutableDictionary dictionary];
        self.comma_memo = [NSMutableDictionary dictionary];
        self.eq_memo = [NSMutableDictionary dictionary];
        self.dot_memo = [NSMutableDictionary dictionary];
        self.semi_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.stat_memo = nil;
    self.assign_memo = nil;
    self.list_memo = nil;
    self.elements_memo = nil;
    self.element_memo = nil;
    self.lbracket_memo = nil;
    self.rbracket_memo = nil;
    self.comma_memo = nil;
    self.eq_memo = nil;
    self.dot_memo = nil;
    self.semi_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_stat_memo removeAllObjects];
    [_assign_memo removeAllObjects];
    [_list_memo removeAllObjects];
    [_elements_memo removeAllObjects];
    [_element_memo removeAllObjects];
    [_lbracket_memo removeAllObjects];
    [_rbracket_memo removeAllObjects];
    [_comma_memo removeAllObjects];
    [_eq_memo removeAllObjects];
    [_dot_memo removeAllObjects];
    [_semi_memo removeAllObjects];
}

- (void)_start {
    
    [self stat]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__stat {
    
    if ([self speculate:^{ [self assign]; [self dot]; }]) {
        [self assign]; 
        [self dot]; 
    } else if ([self speculate:^{ [self list]; [self semi]; }]) {
        [self list]; 
        [self semi]; 
    } else {
        [self raise:@"no viable alternative found in stat"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)stat {
    [self parseRule:@selector(__stat) withMemo:_stat_memo];
}

- (void)__assign {
    
    [self list]; 
    [self eq]; 
    [self list]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)assign {
    [self parseRule:@selector(__assign) withMemo:_assign_memo];
}

- (void)__list {
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)list {
    [self parseRule:@selector(__list) withMemo:_list_memo];
}

- (void)__elements {
    
    [self element]; 
    while ([self predicts:ELEMENTASSIGN_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self comma]; [self element]; }]) {
            [self comma]; 
            [self element]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)elements {
    [self parseRule:@selector(__elements) withMemo:_elements_memo];
}

- (void)__element {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self Number]; 
    } else if ([self predicts:ELEMENTASSIGN_TOKEN_KIND_LBRACKET, 0]) {
        [self list]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)element {
    [self parseRule:@selector(__element) withMemo:_element_memo];
}

- (void)__lbracket {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_LBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)lbracket {
    [self parseRule:@selector(__lbracket) withMemo:_lbracket_memo];
}

- (void)__rbracket {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_RBRACKET]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)rbracket {
    [self parseRule:@selector(__rbracket) withMemo:_rbracket_memo];
}

- (void)__comma {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_COMMA]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)comma {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__eq {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)eq {
    [self parseRule:@selector(__eq) withMemo:_eq_memo];
}

- (void)__dot {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)dot {
    [self parseRule:@selector(__dot) withMemo:_dot_memo];
}

- (void)__semi {
    
    [self match:ELEMENTASSIGN_TOKEN_KIND_SEMI]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

- (void)semi {
    [self parseRule:@selector(__semi) withMemo:_semi_memo];
}

@end