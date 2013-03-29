#import "ElementAssignParser.h"
#import <ParseKit/PKAssembly.h>
#import "PKSRecognitionException.h"
#import "PKSNoViableException.h"

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *assembly;
@end

@interface ElementAssignParser ()
@property (nonatomic, retain) NSDictionary *tokenKindTab;
@end

@implementation ElementAssignParser

- (id)init {
	self = [super init];
	if (self) {
		self.tokenKindTab = @{
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
           @"=" : @(TOKEN_KIND_EQ),
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
	NSLog(@"_start %@", self.assembly);
    
    [self stat]; 

    [self _fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)stat {
	NSLog(@"stat %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        if ([self _speculate:@selector(assign)]) {
            [self assign]; 
        }
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        if ([self _speculate:@selector(list)]) {
            [self list]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in stat"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchStat:)];
}

- (void)assign {
    NSLog(@"assign %@", self.assembly);
    
    [self list]; 
    [self eq]; 
    [self list]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchAssign:)];
}

- (void)list {
	NSLog(@"list %@", self.assembly);
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
	NSLog(@"elements %@", self.assembly);
    
    [self element]; 
    while ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self element]; 
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
	NSLog(@"element %@", self.assembly);
    
    if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self _predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        if ([self _speculate:@selector(list)]) {
            [self list]; 
        }
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in element"];
    }

    [self _fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
	NSLog(@"lbracket %@", self.assembly);
    
    [self _match:TOKEN_KIND_LBRACKET]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
	NSLog(@"rbracket %@", self.assembly);
    
    [self _match:TOKEN_KIND_RBRACKET]; [self _discard];

    [self _fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
	NSLog(@"comma %@", self.assembly);
    
    [self _match:TOKEN_KIND_COMMA]; [self _discard];

    [self _fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)eq {
	NSLog(@"eq %@", self.assembly);
    
    [self _match:TOKEN_KIND_EQ]; 

    [self _fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

@end