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
@end

@interface ExpressionParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation ExpressionParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @">=" : @(TOKEN_KIND_GE),
           @"," : @(TOKEN_KIND_COMMA),
           @"or" : @(TOKEN_KIND_OR),
           @"<" : @(TOKEN_KIND_LT),
           @"<=" : @(TOKEN_KIND_LE),
           @"=" : @(TOKEN_KIND_EQ),
           @"." : @(TOKEN_KIND_DOT),
           @">" : @(TOKEN_KIND_GT),
           @"(" : @(TOKEN_KIND_OPENPAREN),
           @"yes" : @(TOKEN_KIND_YES),
           @"no" : @(TOKEN_KIND_NO),
           @")" : @(TOKEN_KIND_CLOSEPAREN),
           @"!=" : @(TOKEN_KIND_NE),
           @"and" : @(TOKEN_KIND_AND),
        };
	}
	return self;
}

- (void)dealloc {
	self._tokenKindTab = nil;
	[super dealloc];
}

- (NSInteger)tokenKindForString:(NSString *)s {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[s];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)_start {
    
    @try {
        [self expr]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
    
    @try {
        [self orExpr]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orExpr {
    
    @try {
        [self andExpr]; 
        while (LA(1) == TOKEN_KIND_OR) {
            if ([self speculate:^{ [self orTerm]; }]) {
                [self orTerm]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orTerm {
    
    @try {
        [self or]; 
        [self andExpr]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andExpr {
    
    @try {
        [self relExpr]; 
        while (LA(1) == TOKEN_KIND_AND) {
            if ([self speculate:^{ [self andTerm]; }]) {
                [self andTerm]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andTerm {
    
    @try {
        [self and]; 
        [self relExpr]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
    
    @try {
        [self callExpr]; 
        while (LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_LT || LA(1) == TOKEN_KIND_NE || LA(1) == TOKEN_KIND_EQ || LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_GT) {
            if ([self speculate:^{ [self relOp]; [self callExpr]; }]) {
                [self relOp]; 
                [self callExpr]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
    
    @try {
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
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)callExpr {
    
    @try {
        [self primary]; 
        if ((LA(1) == TOKEN_KIND_OPENPAREN) && ([self speculate:^{ [self openParen]; if ((LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_BUILTIN_NUMBER) && ([self speculate:^{ [self argList]; }])) {[self argList]; }[self closeParen]; }])) {
            [self openParen]; 
            if ((LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_BUILTIN_NUMBER) && ([self speculate:^{ [self argList]; }])) {
                [self argList]; 
            }
            [self closeParen]; 
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)argList {
    
    @try {
        [self atom]; 
        while (LA(1) == TOKEN_KIND_COMMA) {
            if ([self speculate:^{ [self comma]; [self atom]; }]) {
                [self comma]; 
                [self atom]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)primary {
    
    @try {
        if (LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self atom]; 
        } else if (LA(1) == TOKEN_KIND_OPENPAREN) {
            [self openParen]; 
            [self expr]; 
            [self closeParen]; 
        } else {
            [self raise:@"no viable alternative found in primary"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)atom {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
            [self obj]; 
        } else if (LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self literal]; 
        } else {
            [self raise:@"no viable alternative found in atom"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)obj {
    
    @try {
        [self id]; 
        while (LA(1) == TOKEN_KIND_DOT) {
            if ([self speculate:^{ [self member]; }]) {
                [self member]; 
            } else {
                return;
            }
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)id {
    
    @try {
        [self Word]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)member {
    
    @try {
        [self dot]; 
        [self id]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
    
    @try {
        if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self QuotedString]; 
        } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
            [self Number]; 
        } else if (LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_YES) {
            [self bool]; 
        } else {
            [self raise:@"no viable alternative found in literal"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
    
    @try {
        if (LA(1) == TOKEN_KIND_YES) {
            [self yes]; 
        } else if (LA(1) == TOKEN_KIND_NO) {
            [self no]; 
        } else {
            [self raise:@"no viable alternative found in bool"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)lt {
    
    @try {
        [self match:TOKEN_KIND_LT]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gt {
    
    @try {
        [self match:TOKEN_KIND_GT]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)eq {
    
    @try {
        [self match:TOKEN_KIND_EQ]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)ne {
    
    @try {
        [self match:TOKEN_KIND_NE]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)le {
    
    @try {
        [self match:TOKEN_KIND_LE]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)ge {
    
    @try {
        [self match:TOKEN_KIND_GE]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)openParen {
    
    @try {
        [self match:TOKEN_KIND_OPENPAREN]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)closeParen {
    
    @try {
        [self match:TOKEN_KIND_CLOSEPAREN]; [self discard:1];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)yes {
    
    @try {
        [self match:TOKEN_KIND_YES]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchYes:)];
}

- (void)no {
    
    @try {
        [self match:TOKEN_KIND_NO]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchNo:)];
}

- (void)dot {
    
    @try {
        [self match:TOKEN_KIND_DOT]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)comma {
    
    @try {
        [self match:TOKEN_KIND_COMMA]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)or {
    
    @try {
        [self match:TOKEN_KIND_OR]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)and {
    
    @try {
        [self match:TOKEN_KIND_AND]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end