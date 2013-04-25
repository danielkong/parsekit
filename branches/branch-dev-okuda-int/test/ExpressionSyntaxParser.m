#import "ExpressionSyntaxParser.h"
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

@interface NSObject ()
- (void)parser:(PKSParser *)p willMatchInterior:(NSString *)ruleName;
- (void)parser:(PKSParser *)p didMatchInterior:(NSString *)ruleName;
- (void)parser:(PKSParser *)p willMatchLeaf:(NSString *)ruleName;
- (void)parser:(PKSParser *)p didMatchLeaf:(NSString *)ruleName;
@end

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

@interface ExpressionSyntaxParser ()
@end

@implementation ExpressionSyntaxParser

- (id)init {
    self = [super init];
    if (self) {
        self._tokenKindTab[@">="] = @(EXPRESSIONSYNTAX_TOKEN_KIND_GE);
        self._tokenKindTab[@","] = @(EXPRESSIONSYNTAX_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"or"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_OR);
        self._tokenKindTab[@"<"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_LT);
        self._tokenKindTab[@"<="] = @(EXPRESSIONSYNTAX_TOKEN_KIND_LE);
        self._tokenKindTab[@"="] = @(EXPRESSIONSYNTAX_TOKEN_KIND_EQ);
        self._tokenKindTab[@"."] = @(EXPRESSIONSYNTAX_TOKEN_KIND_DOT);
        self._tokenKindTab[@">"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_GT);
        self._tokenKindTab[@"("] = @(EXPRESSIONSYNTAX_TOKEN_KIND_OPENPAREN);
        self._tokenKindTab[@"yes"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_YES);
        self._tokenKindTab[@"no"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_NO);
        self._tokenKindTab[@")"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_CLOSEPAREN);
        self._tokenKindTab[@"!="] = @(EXPRESSIONSYNTAX_TOKEN_KIND_NE);
        self._tokenKindTab[@"and"] = @(EXPRESSIONSYNTAX_TOKEN_KIND_AND);

    }
    return self;
}


- (void)_start {
    
    [self expr]; 
    [self matchEOF:YES]; 

}

- (void)expr {
    
    [self.assembler parser:self willMatchInterior:@"expr"];

    [self orExpr]; 

    [self.assembler parser:self didMatchInterior:@"expr"];
}

- (void)orExpr {
    
    [self.assembler parser:self willMatchInterior:@"orExpr"];

    [self andExpr]; 
    while ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_OR, 0]) {
        if ([self speculate:^{ [self orTerm]; }]) {
            [self orTerm]; 
        } else {
            break;
        }
    }

    [self.assembler parser:self didMatchInterior:@"orExpr"];
}

- (void)orTerm {
    
    [self.assembler parser:self willMatchInterior:@"orTerm"];

    [self or]; 
    [self andExpr]; 

    [self.assembler parser:self didMatchInterior:@"orTerm"];
}

- (void)andExpr {
    
    [self.assembler parser:self willMatchInterior:@"andExpr"];

    [self relExpr]; 
    while ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_AND, 0]) {
        if ([self speculate:^{ [self andTerm]; }]) {
            [self andTerm]; 
        } else {
            break;
        }
    }

    [self.assembler parser:self didMatchInterior:@"andExpr"];
}

- (void)andTerm {
    
    [self.assembler parser:self willMatchInterior:@"andTerm"];

    [self and]; 
    [self relExpr]; 

    [self.assembler parser:self didMatchInterior:@"andTerm"];
}

- (void)relExpr {
    
    [self.assembler parser:self willMatchInterior:@"relExpr"];

    [self callExpr]; 
    while ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_EQ, EXPRESSIONSYNTAX_TOKEN_KIND_GE, EXPRESSIONSYNTAX_TOKEN_KIND_GT, EXPRESSIONSYNTAX_TOKEN_KIND_LE, EXPRESSIONSYNTAX_TOKEN_KIND_LT, EXPRESSIONSYNTAX_TOKEN_KIND_NE, 0]) {
        if ([self speculate:^{ [self relOp]; [self callExpr]; }]) {
            [self relOp]; 
            [self callExpr]; 
        } else {
            break;
        }
    }

    [self.assembler parser:self didMatchInterior:@"relExpr"];
}

- (void)relOp {
    
    [self.assembler parser:self willMatchInterior:@"relOp"];

    if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_LT, 0]) {
        [self lt]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_GT, 0]) {
        [self gt]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_EQ, 0]) {
        [self eq]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_NE, 0]) {
        [self ne]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_LE, 0]) {
        [self le]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_GE, 0]) {
        [self ge]; 
    } else {
        [self raise:@"no viable alternative found in relOp"];
    }

    [self.assembler parser:self didMatchInterior:@"relOp"];
}

- (void)callExpr {
    
    [self.assembler parser:self willMatchInterior:@"callExpr"];

    [self primary]; 
    if ([self speculate:^{ [self openParen]; if ([self speculate:^{ [self argList]; }]) {[self argList]; }[self closeParen]; }]) {
        [self openParen]; 
        if ([self speculate:^{ [self argList]; }]) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    [self.assembler parser:self didMatchInterior:@"callExpr"];
}

- (void)argList {
    
    [self.assembler parser:self willMatchInterior:@"argList"];

    [self atom]; 
    while ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self comma]; [self atom]; }]) {
            [self comma]; 
            [self atom]; 
        } else {
            break;
        }
    }

    [self.assembler parser:self didMatchInterior:@"argList"];
}

- (void)primary {
    
    [self.assembler parser:self willMatchInterior:@"primary"];

    if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_NO, EXPRESSIONSYNTAX_TOKEN_KIND_YES, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self atom]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_OPENPAREN, 0]) {
        [self openParen]; 
        [self expr]; 
        [self closeParen]; 
    } else {
        [self raise:@"no viable alternative found in primary"];
    }

    [self.assembler parser:self didMatchInterior:@"primary"];
}

- (void)atom {
    
    [self.assembler parser:self willMatchInterior:@"atom"];

    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self obj]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_NO, EXPRESSIONSYNTAX_TOKEN_KIND_YES, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self literal]; 
    } else {
        [self raise:@"no viable alternative found in atom"];
    }

    [self.assembler parser:self didMatchInterior:@"atom"];
}

- (void)obj {
    
    [self.assembler parser:self willMatchInterior:@"obj"];

    [self id]; 
    while ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_DOT, 0]) {
        if ([self speculate:^{ [self member]; }]) {
            [self member]; 
        } else {
            break;
        }
    }

    [self.assembler parser:self didMatchInterior:@"obj"];
}

- (void)id {
    
    [self.assembler parser:self willMatchLeaf:@"id"];

    [self matchWord:NO];

    [self.assembler parser:self didMatchLeaf:@"id"];
}

- (void)member {
    
    [self.assembler parser:self willMatchInterior:@"member"];

    [self dot]; 
    [self id]; 

    [self.assembler parser:self didMatchInterior:@"member"];
}

- (void)literal {
    
    [self.assembler parser:self willMatchInterior:@"literal"];

    if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self matchQuotedString:NO];
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self matchNumber:NO];
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_NO, EXPRESSIONSYNTAX_TOKEN_KIND_YES, 0]) {
        [self bool]; 
    } else {
        [self raise:@"no viable alternative found in literal"];
    }

    [self.assembler parser:self didMatchInterior:@"literal"];
}

- (void)bool {
    
    [self.assembler parser:self willMatchInterior:@"bool"];

    if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_YES, 0]) {
        [self yes]; 
    } else if ([self predicts:EXPRESSIONSYNTAX_TOKEN_KIND_NO, 0]) {
        [self no]; 
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self.assembler parser:self didMatchInterior:@"bool"];
}

- (void)lt {
    
    [self.assembler parser:self willMatchLeaf:@"lt"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_LT discard:NO];

    [self.assembler parser:self didMatchLeaf:@"lt"];
}

- (void)gt {
    
    [self.assembler parser:self willMatchLeaf:@"gt"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_GT discard:NO];

    [self.assembler parser:self didMatchLeaf:@"gt"];
}

- (void)eq {
    
    [self.assembler parser:self willMatchLeaf:@"eq"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_EQ discard:NO];

    [self.assembler parser:self didMatchLeaf:@"eq"];
}

- (void)ne {
    
    [self.assembler parser:self willMatchLeaf:@"ne"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_NE discard:NO];

    [self.assembler parser:self didMatchLeaf:@"ne"];
}

- (void)le {
    
    [self.assembler parser:self willMatchLeaf:@"le"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_LE discard:NO];

    [self.assembler parser:self didMatchLeaf:@"le"];
}

- (void)ge {
    
    [self.assembler parser:self willMatchLeaf:@"ge"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_GE discard:NO];

    [self.assembler parser:self didMatchLeaf:@"ge"];
}

- (void)openParen {
    
    [self.assembler parser:self willMatchLeaf:@"openParen"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_OPENPAREN discard:NO];

    [self.assembler parser:self didMatchLeaf:@"openParen"];
}

- (void)closeParen {
    
    [self.assembler parser:self willMatchLeaf:@"closeParen"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_CLOSEPAREN discard:YES];

    [self.assembler parser:self didMatchLeaf:@"closeParen"];
}

- (void)yes {
    
    [self.assembler parser:self willMatchLeaf:@"yes"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_YES discard:NO];

    [self.assembler parser:self didMatchLeaf:@"yes"];
}

- (void)no {
    
    [self.assembler parser:self willMatchLeaf:@"no"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_NO discard:NO];

    [self.assembler parser:self didMatchLeaf:@"no"];
}

- (void)dot {
    
    [self.assembler parser:self willMatchLeaf:@"dot"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_DOT discard:NO];

    [self.assembler parser:self didMatchLeaf:@"dot"];
}

- (void)comma {
    
    [self.assembler parser:self willMatchLeaf:@"comma"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_COMMA discard:NO];

    [self.assembler parser:self didMatchLeaf:@"comma"];
}

- (void)or {
    
    [self.assembler parser:self willMatchLeaf:@"or"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_OR discard:NO];

    [self.assembler parser:self didMatchLeaf:@"or"];
}

- (void)and {
    
    [self.assembler parser:self willMatchLeaf:@"and"];

    [self match:EXPRESSIONSYNTAX_TOKEN_KIND_AND discard:NO];

    [self.assembler parser:self didMatchLeaf:@"and"];
}

@end