#import "ElementAssignParser.h"
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

@interface ElementAssignParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation ElementAssignParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
           @"=" : @(TOKEN_KIND_EQ),
           @";" : @(TOKEN_KIND_SEMI),
           @"." : @(TOKEN_KIND_DOT),
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
    
    [self stat]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)stat {
    
    if ([self speculate:^{ [self assign]; [self dot]; }]) {
        [self assign]; 
        [self dot]; 
    } else if ([self speculate:^{ [self list]; [self semi]; }]) {
        [self list]; 
        [self semi]; 
    } else {
        [self raise:@"no viable alternative found in stat"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)assign {
    
    [self list]; 
    [self eq]; 
    [self list]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)list {
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
    
    [self element]; 
    while (LA(1) == TOKEN_KIND_COMMA) {
        [self comma]; 
        [self element]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
    
    if (LA(1) == TOKEN_KIND_BUILTIN_NUMBER) {
        [self Number]; 
    } else if (LA(1) == TOKEN_KIND_LBRACKET) {
        [self list]; 
    } else {
        [self raise:@"no viable alternative found in element"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
    
    [self match:TOKEN_KIND_LBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
    
    [self match:TOKEN_KIND_RBRACKET]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
    
    [self match:TOKEN_KIND_COMMA]; [self discard:1];

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)eq {
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)dot {
    
    [self match:TOKEN_KIND_DOT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)semi {
    
    [self match:TOKEN_KIND_SEMI]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end