#import "ExpressionParser.h"
#import <ParseKit/PKAssembly.h>

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *assembly;
@end

@interface ExpressionParser ()
@property (nonatomic, retain) NSDictionary *tokenKindTab;
@end

@implementation ExpressionParser

- (id)init {
	self = [super init];
	if (self) {
		self.tokenKindTab = @{
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
        };
	}
	return self;
}

- (void)dealloc {
	self.tokenKindTab = nil;
	[super dealloc];
}

- (NSInteger)__tokenKindForString:(NSString *)name {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[name];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)__start {
	//NSLog(@"__start %@", self.assembly);
    
    [self expr]; 

    [self __fireAssemblerSelector:@selector(parser:didMatch__start:)];
}

- (void)expr {
	//NSLog(@"expr %@", self.assembly);
    
    [self orExpr]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orExpr {
	//NSLog(@"orExpr %@", self.assembly);
    
    [self andExpr]; 
    while ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_OR), nil]]) {
        [self orTerm]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orTerm {
	//NSLog(@"orTerm %@", self.assembly);
    
    [self or]; 
    [self andExpr]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andExpr {
	//NSLog(@"andExpr %@", self.assembly);
    
    [self relExpr]; 
    while ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_AND), nil]]) {
        [self andTerm]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andTerm {
	//NSLog(@"andTerm %@", self.assembly);
    
    [self and]; 
    [self relExpr]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
	//NSLog(@"relExpr %@", self.assembly);
    
    [self callExpr]; 
    while ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_LT), @(TOKEN_KIND_GT), @(TOKEN_KIND_GE), @(TOKEN_KIND_NE), @(TOKEN_KIND_LE), @(TOKEN_KIND_EQ), nil]]) {
        [self relOp]; 
        [self callExpr]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
	//NSLog(@"relOp %@", self.assembly);
    
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_LT), nil]]) {
        [self lt]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_GT), nil]]) {
        [self gt]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_EQ), nil]]) {
        [self eq]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_NE), nil]]) {
        [self ne]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_LE), nil]]) {
        [self le]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_GE), nil]]) {
        [self ge]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in relOp"];
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)callExpr {
	//NSLog(@"callExpr %@", self.assembly);
    
    [self primary]; 
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_BUILTIN_WORD), nil]]) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)argList {
	//NSLog(@"argList %@", self.assembly);
    
    [self atom]; 
    while ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self atom]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)primary {
	//NSLog(@"primary %@", self.assembly);
    
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_WORD), nil]]) {
        [self atom]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        [self expr]; 
        [self closeParen]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in primary"];
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)atom {
	//NSLog(@"atom %@", self.assembly);
    
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_WORD), nil]]) {
        [self obj]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), nil]]) {
        [self literal]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in atom"];
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)obj {
	//NSLog(@"obj %@", self.assembly);
    
    [self id]; 
    while ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_DOT), nil]]) {
        [self member]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)id {
	//NSLog(@"id %@", self.assembly);
    
    [self Word]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)member {
	//NSLog(@"member %@", self.assembly);
    
    [self dot]; 
    [self id]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
	//NSLog(@"literal %@", self.assembly);
    
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_QUOTEDSTRING), nil]]) {
        [self QuotedString]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), @(TOKEN_KIND_NO), nil]]) {
        [self bool]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in literal"];
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
	//NSLog(@"bool %@", self.assembly);
    
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), nil]]) {
        [self yes]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), nil]]) {
        [self no]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in bool"];
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)lt {
	//NSLog(@"lt %@", self.assembly);
    
    [self __match:TOKEN_KIND_LT]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gt {
	//NSLog(@"gt %@", self.assembly);
    
    [self __match:TOKEN_KIND_GT]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)eq {
	//NSLog(@"eq %@", self.assembly);
    
    [self __match:TOKEN_KIND_EQ]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)ne {
	//NSLog(@"ne %@", self.assembly);
    
    [self __match:TOKEN_KIND_NE]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)le {
	//NSLog(@"le %@", self.assembly);
    
    [self __match:TOKEN_KIND_LE]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)ge {
	//NSLog(@"ge %@", self.assembly);
    
    [self __match:TOKEN_KIND_GE]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)openParen {
	//NSLog(@"openParen %@", self.assembly);
    
    [self __match:TOKEN_KIND_OPENPAREN]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)closeParen {
	//NSLog(@"closeParen %@", self.assembly);
    
    [self __match:TOKEN_KIND_CLOSEPAREN]; [self __discard];

    [self __fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)yes {
	//NSLog(@"yes %@", self.assembly);
    
    [self __match:TOKEN_KIND_YES]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchYes:)];
}

- (void)no {
	//NSLog(@"no %@", self.assembly);
    
    [self __match:TOKEN_KIND_NO]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchNo:)];
}

- (void)dot {
	//NSLog(@"dot %@", self.assembly);
    
    [self __match:TOKEN_KIND_DOT]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)comma {
	//NSLog(@"comma %@", self.assembly);
    
    [self __match:TOKEN_KIND_COMMA]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)or {
	//NSLog(@"or %@", self.assembly);
    
    [self __match:TOKEN_KIND_OR]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)and {
	//NSLog(@"and %@", self.assembly);
    
    [self __match:TOKEN_KIND_AND]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

@end