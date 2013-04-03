#import "ExpressionActionsParser.h"
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

@interface ExpressionActionsParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation ExpressionActionsParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"no" : @(TOKEN_KIND_NO),
           @"NO" : @(TOKEN_KIND_NO_UPPER),
           @">=" : @(TOKEN_KIND_GE),
           @"," : @(TOKEN_KIND_COMMA),
           @"or" : @(TOKEN_KIND_OR),
           @"<" : @(TOKEN_KIND_LT),
           @"<=" : @(TOKEN_KIND_LE),
           @"=" : @(TOKEN_KIND_EQUALS),
           @"." : @(TOKEN_KIND_DOT),
           @">" : @(TOKEN_KIND_GT),
           @"and" : @(TOKEN_KIND_AND),
           @"(" : @(TOKEN_KIND_OPEN_PAREN),
           @"yes" : @(TOKEN_KIND_YES),
           @")" : @(TOKEN_KIND_CLOSE_PAREN),
           @"!=" : @(TOKEN_KIND_NE),
           @"YES" : @(TOKEN_KIND_YES_UPPER),
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
        [self match:TOKEN_KIND_OR]; [self discard:1];
        [self andExpr]; 
        [self execute:(id)^{
            
	BOOL rhs = POP_BOOL();
	BOOL lhs = POP_BOOL();
	PUSH_BOOL(lhs || rhs);

        }];
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
        [self match:TOKEN_KIND_AND]; [self discard:1];
        [self relExpr]; 
        [self execute:(id)^{
            
	BOOL rhs = POP_BOOL();
	BOOL lhs = POP_BOOL();
	PUSH_BOOL(lhs && rhs);

        }];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
    
    @try {
        [self callExpr]; 
        while (LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_NE || LA(1) == TOKEN_KIND_EQUALS || LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_GT || LA(1) == TOKEN_KIND_LT) {
            if ([self speculate:^{ [self relOpTerm]; }]) {
                [self relOpTerm]; 
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
            [self match:TOKEN_KIND_LT]; 
        } else if (LA(1) == TOKEN_KIND_GT) {
            [self match:TOKEN_KIND_GT]; 
        } else if (LA(1) == TOKEN_KIND_EQUALS) {
            [self match:TOKEN_KIND_EQUALS]; 
        } else if (LA(1) == TOKEN_KIND_NE) {
            [self match:TOKEN_KIND_NE]; 
        } else if (LA(1) == TOKEN_KIND_LE) {
            [self match:TOKEN_KIND_LE]; 
        } else if (LA(1) == TOKEN_KIND_GE) {
            [self match:TOKEN_KIND_GE]; 
        } else {
            [self raise:@"no viable alternative found in relOp"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)relOpTerm {
    
    @try {
        [self relOp]; 
        [self callExpr]; 
        [self execute:(id)^{
            
	NSInteger rhs = POP_INT();
	NSString  *op = POP_STR();
	NSInteger lhs = POP_INT();

	     if (EQ(op, @"<"))  PUSH_BOOL(lhs <  rhs);
	else if (EQ(op, @">"))  PUSH_BOOL(lhs >  rhs);
	else if (EQ(op, @"="))  PUSH_BOOL(lhs == rhs);
	else if (EQ(op, @"!=")) PUSH_BOOL(lhs != rhs);
	else if (EQ(op, @"<=")) PUSH_BOOL(lhs <= rhs);
	else if (EQ(op, @">=")) PUSH_BOOL(lhs >= rhs);

        }];
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOpTerm:)];
}

- (void)callExpr {
    
    @try {
        [self primary]; 
        if ((LA(1) == TOKEN_KIND_OPEN_PAREN) && ([self speculate:^{ [self match:TOKEN_KIND_OPEN_PAREN]; if ((LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_BUILTIN_WORD) && ([self speculate:^{ [self argList]; }])) {[self argList]; }[self match:TOKEN_KIND_CLOSE_PAREN]; }])) {
            [self match:TOKEN_KIND_OPEN_PAREN]; 
            if ((LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_BUILTIN_WORD) && ([self speculate:^{ [self argList]; }])) {
                [self argList]; 
            }
            [self match:TOKEN_KIND_CLOSE_PAREN]; 
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
            if ([self speculate:^{ [self match:TOKEN_KIND_COMMA]; [self atom]; }]) {
                [self match:TOKEN_KIND_COMMA]; 
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
        if (LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_NO) {
            [self atom]; 
        } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
            [self match:TOKEN_KIND_OPEN_PAREN]; 
            [self expr]; 
            [self match:TOKEN_KIND_CLOSE_PAREN]; 
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
        } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER) {
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
        [self match:TOKEN_KIND_DOT]; 
        [self id]; 
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
    
    @try {
        if ([self test:(id)^{ return LA(1) != TOKEN_KIND_YES_UPPER; }] && (LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_YES || LA(1) == TOKEN_KIND_NO || LA(1) == TOKEN_KIND_NO_UPPER)) {
            [self bool]; 
            [self execute:(id)^{
                 PUSH_BOOL(EQ_IGNORE_CASE(POP_STR(), @"yes")); 
            }];
        } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
            [self Number]; 
            [self execute:(id)^{
                 PUSH_FLOAT(POP_FLOAT()); 
            }];
        } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
            [self QuotedString]; 
            [self execute:(id)^{
                 PUSH(POP_STR()); 
            }];
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
            [self match:TOKEN_KIND_YES]; 
        } else if (LA(1) == TOKEN_KIND_YES_UPPER) {
            [self match:TOKEN_KIND_YES_UPPER]; 
        } else if (LA(1) == TOKEN_KIND_NO) {
            [self match:TOKEN_KIND_NO]; 
        } else if ([self test:(id)^{  return NE(LS(1), @"NO");  }] && (LA(1) == TOKEN_KIND_NO_UPPER)) {
            [self match:TOKEN_KIND_NO_UPPER]; 
        } else {
            [self raise:@"no viable alternative found in bool"];
        }
    }
    @catch (PKSRecognitionException *ex) {
        @throw ex;
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end