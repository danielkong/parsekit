#import "ElementAssignParser.h"
#import <ParseKit/PKAssembly.h>
#import "PKSRecognitionException.h"
#import "PKSNoViableException.h"

#define LT(i) ([self _LT:(i)])
#define LA(i) ([self _LA:(i)])

#define POP() ([_assembly pop])
#define PUSH(tok) ([_assembly push:(tok)])
#define ABOVE(tok) ([_assembly objectsAbove:(tok)])

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

- (NSInteger)_tokenKindForString:(NSString *)name {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[name];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)_start {
	//NSLog(@"_start %@", self._assembly);
    
    [self stat]; 

    [self _fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)stat {
	//NSLog(@"stat %@", self._assembly);
    
    if ([self _speculate:^{ [self assign]; [self dot]; }]) {
        [self assign]; 
        [self dot]; 
    } else if ([self _speculate:^{ [self list]; [self semi]; }]) {
        [self list]; 
        [self semi]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in stat"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)assign {
	//NSLog(@"assign %@", self._assembly);
    
    [self list]; 
    [self eq]; 
    [self list]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)list {
	//NSLog(@"list %@", self._assembly);
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
	//NSLog(@"elements %@", self._assembly);
    
    [self element]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self element]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
	//NSLog(@"element %@", self._assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        [self list]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in element"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
	//NSLog(@"lbracket %@", self._assembly);
    
    [self _match:TOKEN_KIND_LBRACKET]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
	//NSLog(@"rbracket %@", self._assembly);
    
    [self _match:TOKEN_KIND_RBRACKET]; [self _discard];

    [self _fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
	//NSLog(@"comma %@", self._assembly);
    
    [self _match:TOKEN_KIND_COMMA]; [self _discard];

    [self _fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)eq {
	//NSLog(@"eq %@", self._assembly);
    
    [self _match:TOKEN_KIND_EQ]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)dot {
	//NSLog(@"dot %@", self._assembly);
    
    [self _match:TOKEN_KIND_DOT]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchDot:)];
}

- (void)semi {
	//NSLog(@"semi %@", self._assembly);
    
    [self _match:TOKEN_KIND_SEMI]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchSemi:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end