#import "ElementParser.h"
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

@interface ElementParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation ElementParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
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
    
    [self list]; 

    [self _fireAssemblerSelector:@selector(parser:didMatch_start:)];
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

@synthesize _tokenKindTab = _tokenKindTab;
@end