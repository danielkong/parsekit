#import "ExpressionParser.h"
#import <ParseKit/PKAssembly.h>
#import "PKSRecognitionException.h"
#import "PKSNoViableException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]

#define POP() [self._assembly pop]
#define PUSH(tok) [self._assembly push:(tok)]
#define ABOVE(fence) [self._assembly objectsAbove:(fence)]

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
	//NSLog(@"_start %@", self._assembly);
    
    [self expr]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)expr {
	//NSLog(@"expr %@", self._assembly);
    
    [self orExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)orExpr {
	//NSLog(@"orExpr %@", self._assembly);
    
    [self andExpr]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_OR), nil]]) {
        [self orTerm]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchOrExpr:)];
}

- (void)orTerm {
	//NSLog(@"orTerm %@", self._assembly);
    
    [self or]; 
    [self andExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOrTerm:)];
}

- (void)andExpr {
	//NSLog(@"andExpr %@", self._assembly);
    
    [self relExpr]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_AND), nil]]) {
        [self andTerm]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAndExpr:)];
}

- (void)andTerm {
	//NSLog(@"andTerm %@", self._assembly);
    
    [self and]; 
    [self relExpr]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAndTerm:)];
}

- (void)relExpr {
	//NSLog(@"relExpr %@", self._assembly);
    
    [self callExpr]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_NE), @(TOKEN_KIND_GE), @(TOKEN_KIND_LE), @(TOKEN_KIND_LT), @(TOKEN_KIND_GT), @(TOKEN_KIND_EQ), nil]]) {
        [self relOp]; 
        [self callExpr]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelExpr:)];
}

- (void)relOp {
	//NSLog(@"relOp %@", self._assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_LT), nil]]) {
        [self lt]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_GT), nil]]) {
        [self gt]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_EQ), nil]]) {
        [self eq]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_NE), nil]]) {
        [self ne]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_LE), nil]]) {
        [self le]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_GE), nil]]) {
        [self ge]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in relOp"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchRelOp:)];
}

- (void)callExpr {
	//NSLog(@"callExpr %@", self._assembly);
    
    [self primary]; 
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_BUILTIN_WORD), @(TOKEN_KIND_NO), nil]]) {
            [self argList]; 
        }
        [self closeParen]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchCallExpr:)];
}

- (void)argList {
	//NSLog(@"argList %@", self._assembly);
    
    [self atom]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self atom]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgList:)];
}

- (void)primary {
	//NSLog(@"primary %@", self._assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_WORD), @(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_NO), nil]]) {
        [self atom]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_OPENPAREN), nil]]) {
        [self openParen]; 
        [self expr]; 
        [self closeParen]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in primary"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPrimary:)];
}

- (void)atom {
	//NSLog(@"atom %@", self._assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_WORD), nil]]) {
        [self obj]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), @(TOKEN_KIND_YES), @(TOKEN_KIND_BUILTIN_QUOTEDSTRING), @(TOKEN_KIND_NO), nil]]) {
        [self literal]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in atom"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAtom:)];
}

- (void)obj {
	//NSLog(@"obj %@", self._assembly);
    
    [self id]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_DOT), nil]]) {
        [self member]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObj:)];
}

- (void)id {
	//NSLog(@"id %@", self._assembly);
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchId:)];
}

- (void)member {
	//NSLog(@"member %@", self._assembly);
    
    [self dot]; 
    [self id]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMember:)];
}

- (void)literal {
	//NSLog(@"literal %@", self._assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_QUOTEDSTRING), nil]]) {
        [self QuotedString]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), @(TOKEN_KIND_NO), nil]]) {
        [self bool]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in literal"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchLiteral:)];
}

- (void)bool {
	//NSLog(@"bool %@", self._assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_YES), nil]]) {
        [self yes]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_NO), nil]]) {
        [self no]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in bool"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchBool:)];
}

- (void)lt {
	//NSLog(@"lt %@", self._assembly);
    
    [self match:TOKEN_KIND_LT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)gt {
	//NSLog(@"gt %@", self._assembly);
    
    [self match:TOKEN_KIND_GT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)eq {
	//NSLog(@"eq %@", self._assembly);
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)ne {
	//NSLog(@"ne %@", self._assembly);
    
    [self match:TOKEN_KIND_NE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNe:)];
}

- (void)le {
	//NSLog(@"le %@", self._assembly);
    
    [self match:TOKEN_KIND_LE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLe:)];
}

- (void)ge {
	//NSLog(@"ge %@", self._assembly);
    
    [self match:TOKEN_KIND_GE]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGe:)];
}

- (void)openParen {
	//NSLog(@"openParen %@", self._assembly);
    
    [self match:TOKEN_KIND_OPENPAREN]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParen:)];
}

- (void)closeParen {
	//NSLog(@"closeParen %@", self._assembly);
    
    [self match:TOKEN_KIND_CLOSEPAREN]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParen:)];
}

- (void)yes {
	//NSLog(@"yes %@", self._assembly);
    
    [self match:TOKEN_KIND_YES]; 

    [self fireAssemblerSelector:@selector(parser:didMatchYes:)];
}

- (void)no {
	//NSLog(@"no %@", self._assembly);
    
    [self match:TOKEN_KIND_NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNo:)];
}

- (void)dot {
	//NSLog(@"dot %@", self._assembly);
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)comma {
	//NSLog(@"comma %@", self._assembly);
    
    [self match:TOKEN_KIND_COMMA]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)or {
	//NSLog(@"or %@", self._assembly);
    
    [self match:TOKEN_KIND_OR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOr:)];
}

- (void)and {
	//NSLog(@"and %@", self._assembly);
    
    [self match:TOKEN_KIND_AND]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAnd:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end