#import "ExpressionActionsParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]

#define POP() [self._assembly pop]
#define TOK() (PKToken *)[self._assembly pop]
#define PUSH(tok) [self._assembly push:(tok)]
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
           @"no" : @(TOKEN_KIND_NO_LOWER),
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
        
	id rhs = POP();
	id lhs = POP();
	PUSH(@([lhs boolValue] || [rhs boolValue]));

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
        
	id rhs = POP();
	id lhs = POP();
	PUSH(@([lhs boolValue] && [rhs boolValue]));

    }];

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
    
    [self callExpr]; 
    while (LA(1) == TOKEN_KIND_NE || LA(1) == TOKEN_KIND_LT || LA(1) == TOKEN_KIND_EQUALS || LA(1) == TOKEN_KIND_LE || LA(1) == TOKEN_KIND_GE || LA(1) == TOKEN_KIND_GT) {
        [self relOp]; 
        [self callExpr]; 
        [self execute:(id)^{
            
	id rhs = POP();
	id lhs = POP();
	PUSH(@([lhs integerValue] >= [rhs integerValue]));

        }];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
    
    if (LA(1) == TOKEN_KIND_LT) {
        [self match:TOKEN_KIND_LT]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_GT) {
        [self match:TOKEN_KIND_GT]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_EQUALS) {
        [self match:TOKEN_KIND_EQUALS]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_NE) {
        [self match:TOKEN_KIND_NE]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_LE) {
        [self match:TOKEN_KIND_LE]; [self discard:1];
    } else if (LA(1) == TOKEN_KIND_GE) {
        [self match:TOKEN_KIND_GE]; [self discard:1];
    } else {
        [self raise:@"no viable alternative found in relOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)callExpr {
    
    [self primary]; 
    if (LA(1) == TOKEN_KIND_OPEN_PAREN) {
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        if (LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING || LA(1) == TOKEN_KIND_BUILTIN_WORD) {
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
    
    if (LA(1) == TOKEN_KIND_BUILTIN_WORD || LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
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
    } else if (LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_BUILTIN_NUMBER || LA(1) == TOKEN_KIND_YES_LOWER || LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
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
    
    if (LA(1) == TOKEN_KIND_BUILTIN_QUOTEDSTRING) {
        [self QuotedString]; 
        [self execute:(id)^{
            
			PKToken *tok = POP();
			PUSH(tok.stringValue);
		
        }];
    } else if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self Number]; 
        [self execute:(id)^{
                        
			PKToken *tok = POP();
            PUSH(@(tok.floatValue));
		
        }];
    } else if (LA(1) == TOKEN_KIND_NO_LOWER || LA(1) == TOKEN_KIND_YES_LOWER) {
        [self bool]; 
    } else {
        [self raise:@"no viable alternative found in literal"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
    
    if (LA(1) == TOKEN_KIND_YES_LOWER) {
        [self match:TOKEN_KIND_YES_LOWER]; 
        [self execute:(id)^{
            POP(); PUSH(@(1));
        }];
    } else if (LA(1) == TOKEN_KIND_NO_LOWER) {
        [self match:TOKEN_KIND_NO_LOWER]; 
        [self execute:(id)^{
            POP(); PUSH(@(0));
        }];
    } else {
        [self raise:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end