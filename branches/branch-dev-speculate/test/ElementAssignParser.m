#import "ElementAssignParser.h"
#import <ParseKit/PKAssembly.h>
#import "PKSRecognitionException.h"
#import "PKSNoViableException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]

#define POP() [_assembly pop]
#define PUSH(tok) [_assembly push:(tok)]
#define ABOVE(fence) [_assembly objectsAbove:(fence)]

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *_assembly;
@end

@interface ElementAssignParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation ElementAssignParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
           @"=" : @(TOKEN_KIND_EQ),
           @"." : @(TOKEN_KIND_DOT),
           @";" : @(TOKEN_KIND_SEMI),
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
    
    [self stat]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)stat {
	//NSLog(@"stat %@", self._assembly);
    
    if ([self speculate:^{ [self assign]; [self dot]; }]) {
        [self assign]; 
        [self dot]; 
    } else if ([self speculate:^{ [self list]; [self semi]; }]) {
        [self list]; 
        [self semi]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in stat"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)assign {
	//NSLog(@"assign %@", self._assembly);
    
    [self list]; 
    [self eq]; 
    [self list]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)list {
	//NSLog(@"list %@", self._assembly);
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
	//NSLog(@"elements %@", self._assembly);
    
    [self element]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self element]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
	//NSLog(@"element %@", self._assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        [self list]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in element"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
	//NSLog(@"lbracket %@", self._assembly);
    
    [self match:TOKEN_KIND_LBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
	//NSLog(@"rbracket %@", self._assembly);
    
    [self match:TOKEN_KIND_RBRACKET]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
	//NSLog(@"comma %@", self._assembly);
    
    [self match:TOKEN_KIND_COMMA]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)eq {
	//NSLog(@"eq %@", self._assembly);
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)dot {
	//NSLog(@"dot %@", self._assembly);
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)semi {
	//NSLog(@"semi %@", self._assembly);
    
    [self match:TOKEN_KIND_SEMI]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end