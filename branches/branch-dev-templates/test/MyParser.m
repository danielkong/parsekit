#import "MyParser.h"

@implementation MyParser

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
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatch_Start:)]) {
        [self.preassembler performSelector:@selector(parser:willMatch_Start:) withObject:self withObject:self.assembly];
    }

    [self expr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatch_Start:)]) {
        [self.assembler performSelector:@selector(parser:didMatch_Start:) withObject:self withObject:self.assembly];
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
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOrexpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOrexpr:) withObject:self withObject:self.assembly];
    }

    [self andExpr:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_OR), nil]]) {
        [self orTerm:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOrexpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOrexpr:) withObject:self withObject:self.assembly];
    }
}

- (void)orTerm:(BOOL)discard {
	NSLog(@"orTerm %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOrterm:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOrterm:) withObject:self withObject:self.assembly];
    }

    [self or:NO];
    [self andExpr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOrterm:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOrterm:) withObject:self withObject:self.assembly];
    }
}

- (void)andExpr:(BOOL)discard {
	NSLog(@"andExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchAndexpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchAndexpr:) withObject:self withObject:self.assembly];
    }

    [self relExpr:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_AND), nil]]) {
        [self andTerm:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchAndexpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAndexpr:) withObject:self withObject:self.assembly];
    }
}

- (void)andTerm:(BOOL)discard {
	NSLog(@"andTerm %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchAndterm:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchAndterm:) withObject:self withObject:self.assembly];
    }

    [self and:NO];
    [self relExpr:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchAndterm:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAndterm:) withObject:self withObject:self.assembly];
    }
}

- (void)relExpr:(BOOL)discard {
	NSLog(@"relExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchRelexpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchRelexpr:) withObject:self withObject:self.assembly];
    }

    [self callExpr:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_LT), nil]]) {
        [self relOp:NO];
        [self callExpr:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchRelexpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRelexpr:) withObject:self withObject:self.assembly];
    }
}

- (void)relOp:(BOOL)discard {
	NSLog(@"relOp %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchRelop:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchRelop:) withObject:self withObject:self.assembly];
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

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchRelop:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRelop:) withObject:self withObject:self.assembly];
    }
}

- (void)callExpr:(BOOL)discard {
	NSLog(@"callExpr %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchCallexpr:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchCallexpr:) withObject:self withObject:self.assembly];
    }

    [self primary:NO];
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_OPENPAREN), nil]]) {
        [self openParen:NO];
        [self argList:NO];
        [self closeParen:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchCallexpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchCallexpr:) withObject:self withObject:self.assembly];
    }
}

- (void)argList:(BOOL)discard {
	NSLog(@"argList %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchArglist:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchArglist:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_EMPTY), nil]]) {
        [self Empty:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_WORD), nil]]) {
        [self atom:NO];
        while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_COMMA), nil]]) {
            [self comma:NO];
            [self atom:NO];
        }
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in argList"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchArglist:)]) {
        [self.assembler performSelector:@selector(parser:didMatchArglist:) withObject:self withObject:self.assembly];
    }
}

- (void)primary:(BOOL)discard {
	NSLog(@"primary %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchPrimary:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchPrimary:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_WORD), nil]]) {
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
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_QUOTEDSTRING), nil]]) {
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
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_YES), nil]]) {
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
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchOpenparen:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchOpenparen:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_OPENPAREN andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchOpenparen:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOpenparen:) withObject:self withObject:self.assembly];
    }
}

- (void)closeParen:(BOOL)discard {
	NSLog(@"closeParen %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchCloseparen:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchCloseparen:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_CLOSEPAREN andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchCloseparen:)]) {
        [self.assembler performSelector:@selector(parser:didMatchCloseparen:) withObject:self withObject:self.assembly];
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