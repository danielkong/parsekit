#import "ExpressionParser.h"

@implementation ExpressionParser

- (id)init {
	self = [super init];
	if (self) {
		
	}
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}

- (NSInteger)tokenUserTypeForString:(NSString *)name {
    static NSDictionary *d = nil;
    if (!d) {
        d = [@{
           @"<" : @(TOKEN_TYPE_LT),
           @">" : @(TOKEN_TYPE_GT),
           @"=" : @(TOKEN_TYPE_EQ),
           @"!=" : @(TOKEN_TYPE_NE),
           @"<=" : @(TOKEN_TYPE_LE),
           @">=" : @(TOKEN_TYPE_GE),
           @"(" : @(TOKEN_TYPE_OPENPAREN),
           @")" : @(TOKEN_TYPE_CLOSEPAREN),
           @"yes" : @(TOKEN_TYPE_YES),
           @"no" : @(TOKEN_TYPE_NO),
           @"." : @(TOKEN_TYPE_DOT),
           @"," : @(TOKEN_TYPE_COMMA),
           @"or" : @(TOKEN_TYPE_OR),
           @"and" : @(TOKEN_TYPE_AND),
        } retain];
    }
    
    NSInteger x = TOKEN_TYPE_BUILTIN_INVALID;
    id obj = d[name];
    if (obj) {
        x = [obj integerValue];
    }
    return x;
}

- (void)_start:(BOOL)discard {
	NSLog(@"_start %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatch_start:)]) {
        [self.preassembler performSelector:@selector(parser:willMatch_start:) withObject:self withObject:self.assembly];
    }

    [self expr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatch_start:)]) {
        [self.assembler performSelector:@selector(parser:didMatch_start:) withObject:self withObject:self.assembly];
    }
}

- (void)expr:(BOOL)discard {
	NSLog(@"expr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchExpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchExpr:) withObject:self withObject:self.assembly];
    }

    [self orExpr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)orExpr:(BOOL)discard {
	NSLog(@"orExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOrExpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOrExpr:) withObject:self withObject:self.assembly];
    }

    [self andExpr:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_OR), nil]]) {
        [self orTerm:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOrExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOrExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)orTerm:(BOOL)discard {
	NSLog(@"orTerm %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOrTerm:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOrTerm:) withObject:self withObject:self.assembly];
    }

    [self or:NO];
    [self andExpr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOrTerm:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOrTerm:) withObject:self withObject:self.assembly];
    }
}

- (void)andExpr:(BOOL)discard {
	NSLog(@"andExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchAndExpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchAndExpr:) withObject:self withObject:self.assembly];
    }

    [self relExpr:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_AND), nil]]) {
        [self andTerm:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchAndExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAndExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)andTerm:(BOOL)discard {
	NSLog(@"andTerm %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchAndTerm:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchAndTerm:) withObject:self withObject:self.assembly];
    }

    [self and:NO];
    [self relExpr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchAndTerm:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAndTerm:) withObject:self withObject:self.assembly];
    }
}

- (void)relExpr:(BOOL)discard {
	NSLog(@"relExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchRelExpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchRelExpr:) withObject:self withObject:self.assembly];
    }

    [self callExpr:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_GE), @(TOKEN_TYPE_LT), @(TOKEN_TYPE_GT), @(TOKEN_TYPE_EQ), @(TOKEN_TYPE_NE), @(TOKEN_TYPE_LE), nil]]) {
        [self relOp:NO];
        [self callExpr:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchRelExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRelExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)relOp:(BOOL)discard {
	NSLog(@"relOp %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchRelOp:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchRelOp:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_LT), nil]]) {
        [self lt:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_GT), nil]]) {
        [self gt:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_EQ), nil]]) {
        [self eq:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_NE), nil]]) {
        [self ne:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_LE), nil]]) {
        [self le:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_GE), nil]]) {
        [self ge:NO];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in relOp"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchRelOp:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRelOp:) withObject:self withObject:self.assembly];
    }
}

- (void)callExpr:(BOOL)discard {
	NSLog(@"callExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchCallExpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchCallExpr:) withObject:self withObject:self.assembly];
    }

    [self primary:NO];
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_OPENPAREN), nil]]) {
        [self openParen:NO];
        if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_NUMBER), @(TOKEN_TYPE_BUILTIN_WORD), @(TOKEN_TYPE_NO), @(TOKEN_TYPE_BUILTIN_QUOTEDSTRING), @(TOKEN_TYPE_YES), nil]]) {
            [self argList:NO];
        }
        [self closeParen:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchCallExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchCallExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)argList:(BOOL)discard {
	NSLog(@"argList %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchArgList:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchArgList:) withObject:self withObject:self.assembly];
    }

    [self atom:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_COMMA), nil]]) {
        [self comma:NO];
        [self atom:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchArgList:)]) {
        [self.assembler performSelector:@selector(parser:didMatchArgList:) withObject:self withObject:self.assembly];
    }
}

- (void)primary:(BOOL)discard {
	NSLog(@"primary %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchPrimary:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchPrimary:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_NUMBER), @(TOKEN_TYPE_NO), @(TOKEN_TYPE_BUILTIN_WORD), @(TOKEN_TYPE_BUILTIN_QUOTEDSTRING), @(TOKEN_TYPE_YES), nil]]) {
        [self atom:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_OPENPAREN), nil]]) {
        [self openParen:NO];
        [self expr:NO];
        [self closeParen:NO];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in primary"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchPrimary:)]) {
        [self.assembler performSelector:@selector(parser:didMatchPrimary:) withObject:self withObject:self.assembly];
    }
}

- (void)atom:(BOOL)discard {
	NSLog(@"atom %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchAtom:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchAtom:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_WORD), nil]]) {
        [self obj:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_NUMBER), @(TOKEN_TYPE_NO), @(TOKEN_TYPE_BUILTIN_QUOTEDSTRING), @(TOKEN_TYPE_YES), nil]]) {
        [self literal:NO];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in atom"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchAtom:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAtom:) withObject:self withObject:self.assembly];
    }
}

- (void)obj:(BOOL)discard {
	NSLog(@"obj %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchObj:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchObj:) withObject:self withObject:self.assembly];
    }

    [self id:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_DOT), nil]]) {
        [self member:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchObj:)]) {
        [self.assembler performSelector:@selector(parser:didMatchObj:) withObject:self withObject:self.assembly];
    }
}

- (void)id:(BOOL)discard {
	NSLog(@"id %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchId:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchId:) withObject:self withObject:self.assembly];
    }

    [self Word:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchId:)]) {
        [self.assembler performSelector:@selector(parser:didMatchId:) withObject:self withObject:self.assembly];
    }
}

- (void)member:(BOOL)discard {
	NSLog(@"member %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchMember:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchMember:) withObject:self withObject:self.assembly];
    }

    [self dot:NO];
    [self id:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchMember:)]) {
        [self.assembler performSelector:@selector(parser:didMatchMember:) withObject:self withObject:self.assembly];
    }
}

- (void)literal:(BOOL)discard {
	NSLog(@"literal %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchLiteral:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchLiteral:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_QUOTEDSTRING), nil]]) {
        [self QuotedString:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_NUMBER), nil]]) {
        [self Number:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_YES), @(TOKEN_TYPE_NO), nil]]) {
        [self bool:NO];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in literal"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchLiteral:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLiteral:) withObject:self withObject:self.assembly];
    }
}

- (void)bool:(BOOL)discard {
	NSLog(@"bool %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchBool:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchBool:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_YES), nil]]) {
        [self yes:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_NO), nil]]) {
        [self no:NO];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in bool"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchBool:)]) {
        [self.assembler performSelector:@selector(parser:didMatchBool:) withObject:self withObject:self.assembly];
    }
}

- (void)lt:(BOOL)discard {
	NSLog(@"lt %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchLt:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchLt:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_LT andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchLt:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLt:) withObject:self withObject:self.assembly];
    }
}

- (void)gt:(BOOL)discard {
	NSLog(@"gt %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchGt:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchGt:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_GT andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchGt:)]) {
        [self.assembler performSelector:@selector(parser:didMatchGt:) withObject:self withObject:self.assembly];
    }
}

- (void)eq:(BOOL)discard {
	NSLog(@"eq %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchEq:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchEq:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_EQ andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchEq:)]) {
        [self.assembler performSelector:@selector(parser:didMatchEq:) withObject:self withObject:self.assembly];
    }
}

- (void)ne:(BOOL)discard {
	NSLog(@"ne %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchNe:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchNe:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_NE andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchNe:)]) {
        [self.assembler performSelector:@selector(parser:didMatchNe:) withObject:self withObject:self.assembly];
    }
}

- (void)le:(BOOL)discard {
	NSLog(@"le %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchLe:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchLe:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_LE andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchLe:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLe:) withObject:self withObject:self.assembly];
    }
}

- (void)ge:(BOOL)discard {
	NSLog(@"ge %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchGe:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchGe:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_GE andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchGe:)]) {
        [self.assembler performSelector:@selector(parser:didMatchGe:) withObject:self withObject:self.assembly];
    }
}

- (void)openParen:(BOOL)discard {
	NSLog(@"openParen %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOpenParen:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOpenParen:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_OPENPAREN andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOpenParen:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOpenParen:) withObject:self withObject:self.assembly];
    }
}

- (void)closeParen:(BOOL)discard {
	NSLog(@"closeParen %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchCloseParen:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchCloseParen:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_CLOSEPAREN andDiscard:YES];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchCloseParen:)]) {
        [self.assembler performSelector:@selector(parser:didMatchCloseParen:) withObject:self withObject:self.assembly];
    }
}

- (void)yes:(BOOL)discard {
	NSLog(@"yes %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchYes:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchYes:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_YES andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchYes:)]) {
        [self.assembler performSelector:@selector(parser:didMatchYes:) withObject:self withObject:self.assembly];
    }
}

- (void)no:(BOOL)discard {
	NSLog(@"no %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchNo:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchNo:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_NO andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchNo:)]) {
        [self.assembler performSelector:@selector(parser:didMatchNo:) withObject:self withObject:self.assembly];
    }
}

- (void)dot:(BOOL)discard {
	NSLog(@"dot %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchDot:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchDot:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_DOT andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchDot:)]) {
        [self.assembler performSelector:@selector(parser:didMatchDot:) withObject:self withObject:self.assembly];
    }
}

- (void)comma:(BOOL)discard {
	NSLog(@"comma %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchComma:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchComma:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_COMMA andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchComma:)]) {
        [self.assembler performSelector:@selector(parser:didMatchComma:) withObject:self withObject:self.assembly];
    }
}

- (void)or:(BOOL)discard {
	NSLog(@"or %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOr:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_OR andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOr:) withObject:self withObject:self.assembly];
    }
}

- (void)and:(BOOL)discard {
	NSLog(@"and %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchAnd:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchAnd:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_AND andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchAnd:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAnd:) withObject:self withObject:self.assembly];
    }
}

@end