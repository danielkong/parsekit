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

- (NSInteger)tokenKindForString:(NSString *)name {
    static NSDictionary *d = nil;
    if (!d) {
        d = [@{
           @"<" : @(TOKEN_KIND_LT),
           @">" : @(TOKEN_KIND_GT),
           @"=" : @(TOKEN_KIND_EQ),
           @"!=" : @(TOKEN_KIND_NE),
           @"<=" : @(TOKEN_KIND_LE),
           @">=" : @(TOKEN_KIND_GE),
           @"(" : @(TOKEN_KIND_OPENPAREN),
           @")" : @(TOKEN_KIND_CLOSEPAREN),
           @"yes" : @(TOKEN_KIND_YES),
           @"no" : @(TOKEN_KIND_NO),
           @"." : @(TOKEN_KIND_DOT),
           @"," : @(TOKEN_KIND_COMMA),
           @"or" : @(TOKEN_KIND_OR),
           @"and" : @(TOKEN_KIND_AND),
        } retain];
    }
    
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;
    id obj = d[name];
    if (obj) {
        x = [obj integerValue];
    }
    return x;
}

- (void)_start {
	NSLog(@"_start %@", self.assembly);
    
    [self expr]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatch_start:)]) {
        [self.assembler performSelector:@selector(parser:didMatch_start:) withObject:self withObject:self.assembly];
    }
}

- (void)expr {
	NSLog(@"expr %@", self.assembly);
    
    [self orExpr]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)orExpr {
	NSLog(@"orExpr %@", self.assembly);
    
    [self andExpr]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_OR), nil]]) {
        [self orTerm]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchOrExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOrExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)orTerm {
	NSLog(@"orTerm %@", self.assembly);
    
    [self or]; 
    [self andExpr]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchOrTerm:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOrTerm:) withObject:self withObject:self.assembly];
    }
}

- (void)andExpr {
	NSLog(@"andExpr %@", self.assembly);
    
    [self relExpr]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_AND), nil]]) {
        [self andTerm]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchAndExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAndExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)andTerm {
	NSLog(@"andTerm %@", self.assembly);
    
    [self and]; 
    [self relExpr]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchAndTerm:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAndTerm:) withObject:self withObject:self.assembly];
    }
}

- (void)relExpr {
	NSLog(@"relExpr %@", self.assembly);
    
    [self callExpr]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LT), @(TOKEN_KIND_GE), @(TOKEN_KIND_NE), @(TOKEN_KIND_LE), @(TOKEN_KIND_EQ), @(TOKEN_KIND_GT), nil]]) {
        [self relOp]; 
        [self callExpr]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchRelExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRelExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)relOp {
	NSLog(@"relOp %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LT), nil]]) {
        [self lt]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_GT), nil]]) {
        [self gt]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_EQ), nil]]) {
        [self eq]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NE), nil]]) {
        [self ne]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LE), nil]]) {
        [self le]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_GE), nil]]) {
        [self ge]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in relOp"];
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchRelOp:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRelOp:) withObject:self withObject:self.assembly];
    }
}

- (void)callExpr {
	NSLog(@"callExpr %@", self.assembly);
    
    [self primary]; 
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_BUILTIN_WORD), @(TOKEN_KIND_NO), @(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchCallExpr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchCallExpr:) withObject:self withObject:self.assembly];
    }
}

- (void)argList {
	NSLog(@"argList %@", self.assembly);
    
    [self atom]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self atom]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchArgList:)]) {
        [self.assembler performSelector:@selector(parser:didMatchArgList:) withObject:self withObject:self.assembly];
    }
}

- (void)primary {
	NSLog(@"primary %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_BUILTIN_WORD), @(TOKEN_KIND_NO), @(TOKEN_KIND_YES), nil]]) {
        [self atom]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        [self expr]; 
        [self closeParen]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in primary"];
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchPrimary:)]) {
        [self.assembler performSelector:@selector(parser:didMatchPrimary:) withObject:self withObject:self.assembly];
    }
}

- (void)atom {
	NSLog(@"atom %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_WORD), nil]]) {
        [self obj]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_NO), nil]]) {
        [self literal]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in atom"];
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchAtom:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAtom:) withObject:self withObject:self.assembly];
    }
}

- (void)obj {
	NSLog(@"obj %@", self.assembly);
    
    [self id]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_DOT), nil]]) {
        [self member]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchObj:)]) {
        [self.assembler performSelector:@selector(parser:didMatchObj:) withObject:self withObject:self.assembly];
    }
}

- (void)id {
	NSLog(@"id %@", self.assembly);
    
    [self Word]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchId:)]) {
        [self.assembler performSelector:@selector(parser:didMatchId:) withObject:self withObject:self.assembly];
    }
}

- (void)member {
	NSLog(@"member %@", self.assembly);
    
    [self dot]; 
    [self id]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchMember:)]) {
        [self.assembler performSelector:@selector(parser:didMatchMember:) withObject:self withObject:self.assembly];
    }
}

- (void)literal {
	NSLog(@"literal %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_QUOTEDSTRING), nil]]) {
        [self QuotedString]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), @(TOKEN_KIND_YES), nil]]) {
        [self bool]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in literal"];
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchLiteral:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLiteral:) withObject:self withObject:self.assembly];
    }
}

- (void)bool {
	NSLog(@"bool %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), nil]]) {
        [self yes]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), nil]]) {
        [self no]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in bool"];
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchBool:)]) {
        [self.assembler performSelector:@selector(parser:didMatchBool:) withObject:self withObject:self.assembly];
    }
}

- (void)lt {
	NSLog(@"lt %@", self.assembly);
    
    [self _match:TOKEN_KIND_LT]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchLt:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLt:) withObject:self withObject:self.assembly];
    }
}

- (void)gt {
	NSLog(@"gt %@", self.assembly);
    
    [self _match:TOKEN_KIND_GT]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchGt:)]) {
        [self.assembler performSelector:@selector(parser:didMatchGt:) withObject:self withObject:self.assembly];
    }
}

- (void)eq {
	NSLog(@"eq %@", self.assembly);
    
    [self _match:TOKEN_KIND_EQ]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchEq:)]) {
        [self.assembler performSelector:@selector(parser:didMatchEq:) withObject:self withObject:self.assembly];
    }
}

- (void)ne {
	NSLog(@"ne %@", self.assembly);
    
    [self _match:TOKEN_KIND_NE]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchNe:)]) {
        [self.assembler performSelector:@selector(parser:didMatchNe:) withObject:self withObject:self.assembly];
    }
}

- (void)le {
	NSLog(@"le %@", self.assembly);
    
    [self _match:TOKEN_KIND_LE]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchLe:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLe:) withObject:self withObject:self.assembly];
    }
}

- (void)ge {
	NSLog(@"ge %@", self.assembly);
    
    [self _match:TOKEN_KIND_GE]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchGe:)]) {
        [self.assembler performSelector:@selector(parser:didMatchGe:) withObject:self withObject:self.assembly];
    }
}

- (void)openParen {
	NSLog(@"openParen %@", self.assembly);
    
    [self _match:TOKEN_KIND_OPENPAREN]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchOpenParen:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOpenParen:) withObject:self withObject:self.assembly];
    }
}

- (void)closeParen {
	NSLog(@"closeParen %@", self.assembly);
    
    [self _match:TOKEN_KIND_CLOSEPAREN]; [self _discard];

    if ([self.assembler respondsToSelector:@selector(parser:didMatchCloseParen:)]) {
        [self.assembler performSelector:@selector(parser:didMatchCloseParen:) withObject:self withObject:self.assembly];
    }
}

- (void)yes {
	NSLog(@"yes %@", self.assembly);
    
    [self _match:TOKEN_KIND_YES]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchYes:)]) {
        [self.assembler performSelector:@selector(parser:didMatchYes:) withObject:self withObject:self.assembly];
    }
}

- (void)no {
	NSLog(@"no %@", self.assembly);
    
    [self _match:TOKEN_KIND_NO]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchNo:)]) {
        [self.assembler performSelector:@selector(parser:didMatchNo:) withObject:self withObject:self.assembly];
    }
}

- (void)dot {
	NSLog(@"dot %@", self.assembly);
    
    [self _match:TOKEN_KIND_DOT]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchDot:)]) {
        [self.assembler performSelector:@selector(parser:didMatchDot:) withObject:self withObject:self.assembly];
    }
}

- (void)comma {
	NSLog(@"comma %@", self.assembly);
    
    [self _match:TOKEN_KIND_COMMA]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchComma:)]) {
        [self.assembler performSelector:@selector(parser:didMatchComma:) withObject:self withObject:self.assembly];
    }
}

- (void)or {
	NSLog(@"or %@", self.assembly);
    
    [self _match:TOKEN_KIND_OR]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchOr:)]) {
        [self.assembler performSelector:@selector(parser:didMatchOr:) withObject:self withObject:self.assembly];
    }
}

- (void)and {
	NSLog(@"and %@", self.assembly);
    
    [self _match:TOKEN_KIND_AND]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchAnd:)]) {
        [self.assembler performSelector:@selector(parser:didMatchAnd:) withObject:self withObject:self.assembly];
    }
}

@end