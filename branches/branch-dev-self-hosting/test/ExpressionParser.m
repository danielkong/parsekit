#import "ExpressionParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self._assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self._assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self._assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *_assembly;
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

@interface ExpressionParser ()
@end

@implementation ExpressionParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@">="] = @(TOKEN_KIND_GE);
        self._tokenKindTab[@","] = @(TOKEN_KIND_COMMA);
        self._tokenKindTab[@"or"] = @(TOKEN_KIND_OR);
        self._tokenKindTab[@"<"] = @(TOKEN_KIND_LT);
        self._tokenKindTab[@"<="] = @(TOKEN_KIND_LE);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQ);
        self._tokenKindTab[@"."] = @(TOKEN_KIND_DOT);
        self._tokenKindTab[@">"] = @(TOKEN_KIND_GT);
        self._tokenKindTab[@"("] = @(TOKEN_KIND_OPENPAREN);
        self._tokenKindTab[@"yes"] = @(TOKEN_KIND_YES);
        self._tokenKindTab[@"no"] = @(TOKEN_KIND_NO);
        self._tokenKindTab[@")"] = @(TOKEN_KIND_CLOSEPAREN);
        self._tokenKindTab[@"!="] = @(TOKEN_KIND_NE);
        self._tokenKindTab[@"and"] = @(TOKEN_KIND_AND);

    }
	return self;
}


- (void)_start {
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
    
    [self orExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orExpr {
    
    [self andExpr]; 
    while (LA(1) == TOKEN_KIND_OR) {
        if ([self speculate:^{ [self orTerm]; }]) {
            [self orTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orTerm {
    
    [self or]; 
    [self andExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andExpr {
    
    [self relExpr]; 
    while (LA(1) == TOKEN_KIND_AND) {
        if ([self speculate:^{ [self andTerm]; }]) {
            [self andTerm]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andTerm {
    
    [self and]; 
    [self relExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
    
    [self callExpr]; 
    while (LA(1) == TOKEN_KIND_EQ || LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_GT || LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_LT || LA(1) == TOKEN_KIND_NE) {
        if ([self speculate:^{ [self relOp]; [self callExpr]; }]) {
            [self relOp]; 
            [self callExpr]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
    
    if (LA(1) == TOKEN_KIND_LT) {
        [self lt]; 
    } else if (LA(1) == TOKEN_KIND_GT) {
        [self gt]; 
    } else if (LA(1) == TOKEN_KIND_EQ) {
        [self eq]; 
    } else if (LA(1) == TOKEN_KIND_NE) {
        [self ne]; 
    } else if (LA(1) == TOKEN_KIND_LE) {
        [self le]; 
    } else if (LA(1) == TOKEN_KIND_GE) {
        [self ge]; 
    } else {
        [self raise:@"no viable alternative found in relOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)callExpr {
    
    [self primary]; 
    if ((LA(1) == TOKEN_KIND_OPENPAREN) && ([self speculate:^{ [self openParen]; if ((LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) && ([self speculate:^{ [self argList]; }])) {[self argList]; }[self closeParen]; }])) {
        [self openParen]; 
        if ((LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) && ([self speculate:^{ [self argList]; }])) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)argList {
    
    [self atom]; 
    while (LA(1) == TOKEN_KIND_COMMA) {
        if ([self speculate:^{ [self comma]; [self atom]; }]) {
            [self comma]; 
            [self atom]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)primary {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
        [self atom]; 
    } else if (LA(1) == TOKEN_KIND_OPENPAREN) {
        [self openParen]; 
        [self expr]; 
        [self closeParen]; 
    } else {
        [self raise:@"no viable alternative found in primary"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)atom {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self obj]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
        [self literal]; 
    } else {
        [self raise:@"no viable alternative found in atom"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)obj {
    
    [self id]; 
    while (LA(1) == TOKEN_KIND_DOT) {
        if ([self speculate:^{ [self member]; }]) {
            [self member]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)id {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)member {
    
    [self dot]; 
    [self id]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self QuotedString]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self Number]; 
    } else if (LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
        [self bool]; 
    } else {
        [self raise:@"no viable alternative found in literal"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
    
    if (LA(1) == TOKEN_KIND_YES) {
        [self yes]; 
    } else if (LA(1) == TOKEN_KIND_NO) {
        [self no]; 
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)lt {
    
    [self match:TOKEN_KIND_LT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gt {
    
    [self match:TOKEN_KIND_GT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)eq {
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)ne {
    
    [self match:TOKEN_KIND_NE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)le {
    
    [self match:TOKEN_KIND_LE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)ge {
    
    [self match:TOKEN_KIND_GE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)openParen {
    
    [self match:TOKEN_KIND_OPENPAREN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)closeParen {
    
    [self match:TOKEN_KIND_CLOSEPAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)yes {
    
    [self match:TOKEN_KIND_YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchYes:)];
}

- (void)no {
    
    [self match:TOKEN_KIND_NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNo:)];
}

- (void)dot {
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)comma {
    
    [self match:TOKEN_KIND_COMMA]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)or {
    
    [self match:TOKEN_KIND_OR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)and {
    
    [self match:TOKEN_KIND_AND]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

@end