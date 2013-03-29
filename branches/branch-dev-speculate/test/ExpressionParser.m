#import "ExpressionParser.h"
#import <ParseKit/PKAssembly.h>
#import "PKSRecognitionException.h"
#import "PKSNoViableException.h"

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

- (NSInteger)_tokenKindForString:(NSString *)name {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[name];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)_start {
	//NSLog(@"_start %@", self.assembly);
    
    [self expr]; 

    [self _fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
	//NSLog(@"expr %@", self.assembly);
    
    [self orExpr]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orExpr {
	//NSLog(@"orExpr %@", self.assembly);
    
    [self andExpr]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_OR), nil]]) {
        [self orTerm]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orTerm {
	//NSLog(@"orTerm %@", self.assembly);
    
    [self or]; 
    [self andExpr]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andExpr {
	//NSLog(@"andExpr %@", self.assembly);
    
    [self relExpr]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_AND), nil]]) {
        [self andTerm]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andTerm {
	//NSLog(@"andTerm %@", self.assembly);
    
    [self and]; 
    [self relExpr]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
	//NSLog(@"relExpr %@", self.assembly);
    
    [self callExpr]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NE), @(TOKEN_KIND_GT), @(TOKEN_KIND_LT), @(TOKEN_KIND_GE), @(TOKEN_KIND_EQ), @(TOKEN_KIND_LE), nil]]) {
        [self relOp]; 
        [self callExpr]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
	//NSLog(@"relOp %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LT), nil]]) {
        if ([self _speculate:@selector(lt)]) {
            [self lt]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_GT), nil]]) {
        if ([self _speculate:@selector(gt)]) {
            [self gt]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_EQ), nil]]) {
        if ([self _speculate:@selector(eq)]) {
            [self eq]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NE), nil]]) {
        if ([self _speculate:@selector(ne)]) {
            [self ne]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LE), nil]]) {
        if ([self _speculate:@selector(le)]) {
            [self le]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_GE), nil]]) {
        if ([self _speculate:@selector(ge)]) {
            [self ge]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in relOp"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)callExpr {
	//NSLog(@"callExpr %@", self.assembly);
    
    [self primary]; 
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_NO), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_WORD), nil]]) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)argList {
	//NSLog(@"argList %@", self.assembly);
    
    [self atom]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self atom]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)primary {
	//NSLog(@"primary %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), @(TOKEN_KIND_BUILTIN_WORD), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), nil]]) {
        if ([self _speculate:@selector(atom)]) {
            [self atom]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        if ([self _speculate:@selector(openParen)]) {
            [self openParen]; 
        }
        if ([self _speculate:@selector(expr)]) {
            [self expr]; 
        }
        if ([self _speculate:@selector(closeParen)]) {
            [self closeParen]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in primary"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)atom {
	//NSLog(@"atom %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_WORD), nil]]) {
        if ([self _speculate:@selector(obj)]) {
            [self obj]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_NO), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        if ([self _speculate:@selector(literal)]) {
            [self literal]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in atom"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)obj {
	//NSLog(@"obj %@", self.assembly);
    
    [self id]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_DOT), nil]]) {
        [self member]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)id {
	//NSLog(@"id %@", self.assembly);
    
    [self Word]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)member {
	//NSLog(@"member %@", self.assembly);
    
    [self dot]; 
    [self id]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
	//NSLog(@"literal %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_QUOTEDSTRING), nil]]) {
        [self QuotedString]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), @(TOKEN_KIND_YES), nil]]) {
        if ([self _speculate:@selector(bool)]) {
            [self bool]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in literal"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
	//NSLog(@"bool %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), nil]]) {
        if ([self _speculate:@selector(yes)]) {
            [self yes]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), nil]]) {
        if ([self _speculate:@selector(no)]) {
            [self no]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in bool"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)lt {
	//NSLog(@"lt %@", self.assembly);
    
    [self _match:TOKEN_KIND_LT]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gt {
	//NSLog(@"gt %@", self.assembly);
    
    [self _match:TOKEN_KIND_GT]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)eq {
	//NSLog(@"eq %@", self.assembly);
    
    [self _match:TOKEN_KIND_EQ]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)ne {
	//NSLog(@"ne %@", self.assembly);
    
    [self _match:TOKEN_KIND_NE]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)le {
	//NSLog(@"le %@", self.assembly);
    
    [self _match:TOKEN_KIND_LE]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)ge {
	//NSLog(@"ge %@", self.assembly);
    
    [self _match:TOKEN_KIND_GE]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)openParen {
	//NSLog(@"openParen %@", self.assembly);
    
    [self _match:TOKEN_KIND_OPENPAREN]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)closeParen {
	//NSLog(@"closeParen %@", self.assembly);
    
    [self _match:TOKEN_KIND_CLOSEPAREN]; [self _discard];

    [self _fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)yes {
	//NSLog(@"yes %@", self.assembly);
    
    [self _match:TOKEN_KIND_YES]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchYes:)];
}

- (void)no {
	//NSLog(@"no %@", self.assembly);
    
    [self _match:TOKEN_KIND_NO]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchNo:)];
}

- (void)dot {
	//NSLog(@"dot %@", self.assembly);
    
    [self _match:TOKEN_KIND_DOT]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)comma {
	//NSLog(@"comma %@", self.assembly);
    
    [self _match:TOKEN_KIND_COMMA]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)or {
	//NSLog(@"or %@", self.assembly);
    
    [self _match:TOKEN_KIND_OR]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)and {
	//NSLog(@"and %@", self.assembly);
    
    [self _match:TOKEN_KIND_AND]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

@end