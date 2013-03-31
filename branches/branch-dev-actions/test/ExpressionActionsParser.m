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

#define EQUALS(a, b) [(a) isEqual:(b)]

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
           @"no" : @(TOKEN_KIND_NO_LOWER),
           @"NO" : @(TOKEN_KIND_NO_UPPER),
           @">=" : @(TOKEN_KIND_GE),
           @"," : @(TOKEN_KIND_COMMA),
           @"or" : @(TOKEN_KIND_OR_LOWER),
           @"<" : @(TOKEN_KIND_LT),
           @"<=" : @(TOKEN_KIND_LE),
           @"=" : @(TOKEN_KIND_EQUALS),
           @"." : @(TOKEN_KIND_DOT),
           @">" : @(TOKEN_KIND_GT),
           @"and" : @(TOKEN_KIND_AND_LOWER),
           @"(" : @(TOKEN_KIND_OPEN_PAREN),
           @"yes" : @(TOKEN_KIND_YES_LOWER),
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
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
    
    [self orExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orExpr {
    
    [self andExpr]; 
    while (LA(1) == TOKEN_KIND_OR_LOWER) {
        [self orTerm]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orTerm {
    
    [self match:TOKEN_KIND_OR_LOWER]; [self discard:1];
    [self andExpr]; 
    [self execute:(id)^{
        
	BOOL rhs = POP_BOOL();
	BOOL lhs = POP_BOOL();
	PUSH_BOOL(lhs || rhs);

    }];

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andExpr {
    
    [self relExpr]; 
    while (LA(1) == TOKEN_KIND_AND_LOWER) {
        [self andTerm]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andTerm {
    
    [self match:TOKEN_KIND_AND_LOWER]; [self discard:1];
    [self relExpr]; 
    [self execute:(id)^{
        
	BOOL rhs = POP_BOOL();
	BOOL lhs = POP_BOOL();
	PUSH_BOOL(lhs && rhs);

    }];

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
    
    [self callExpr]; 
    while (LA(1) == TOKEN_KIND_EQUALS || LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_LT || LA(1) == TOKEN_KIND_GT || LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_NE) {
        [self relOpTerm]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
    
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

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)relOpTerm {
    
    [self relOp]; 
    [self callExpr]; 
    [self execute:(id)^{
        
	NSInteger rhs = POP_INT();
	NSString  *op = POP_STR();
	NSInteger lhs = POP_INT();

	     if (EQUALS(op, @"<"))  PUSH_BOOL(lhs <  rhs);
	else if (EQUALS(op, @">"))  PUSH_BOOL(lhs >  rhs);
	else if (EQUALS(op, @"="))  PUSH_BOOL(lhs == rhs);
	else if (EQUALS(op, @"!=")) PUSH_BOOL(lhs != rhs);
	else if (EQUALS(op, @"<=")) PUSH_BOOL(lhs <= rhs);
	else if (EQUALS(op, @">=")) PUSH_BOOL(lhs >= rhs);

    }];

    [self fireAssemblerSelector:@selector(parser:didMatchRelOpTerm:)];
}

- (void)callExpr {
    
    [self primary]; 
    if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_NO_LOWER) {
            [self argList]; 
        }
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)argList {
    
    [self atom]; 
    while (LA(1) == TOKEN_KIND_COMMA) {
        [self match:TOKEN_KIND_COMMA]; 
        [self atom]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)primary {
    
    if (LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_NO_UPPER || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self atom]; 
    } else if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self expr]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
    } else {
        [self raise:@"no viable alternative found in primary"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)atom {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD) {
        [self obj]; 
    } else if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_NO_UPPER) {
        [self literal]; 
    } else {
        [self raise:@"no viable alternative found in atom"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)obj {
    
    [self id]; 
    while (LA(1) == TOKEN_KIND_DOT) {
        [self member]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)id {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)member {
    
    [self match:TOKEN_KIND_DOT]; 
    [self id]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
    
    if ([self test:(id)^{ return LA(1) != TOKEN_KIND_YES_UPPER; }] && (LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_YES_UPPER || LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_NO_UPPER)) {
        [self bool]; 
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

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
    
    if (LA(1) == TOKEN_KIND_YES_LOWER) {
        [self match:TOKEN_KIND_YES_LOWER]; 
        [self execute:(id)^{
            POP(); PUSH_BOOL(YES);
        }];
    } else if (LA(1) == TOKEN_KIND_YES_UPPER) {
        [self match:TOKEN_KIND_YES_UPPER]; 
        [self execute:(id)^{
            POP(); PUSH_BOOL(YES);
        }];
    } else if (LA(1) == TOKEN_KIND_NO_LOWER) {
        [self match:TOKEN_KIND_NO_LOWER]; 
        [self execute:(id)^{
            POP(); PUSH_BOOL(NO);
        }];
    } else if ([self test:(id)^{  return !EQUALS(LS(1), @"NO");  }] && (LA(1) == TOKEN_KIND_NO_UPPER)) {
        [self match:TOKEN_KIND_NO_UPPER]; 
        [self execute:(id)^{
            POP(); PUSH_BOOL(NO);
        }];
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end