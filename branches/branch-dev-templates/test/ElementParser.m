#import "ElementParser.h"
#import <ParseKit/PKAssembly.h>
#import "PKSRecognitionException.h"
#import "PKSNoViableException.h"

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *assembly;
@end

@interface ElementParser ()
@property (nonatomic, retain) NSDictionary *tokenKindTab;
@end

@implementation ElementParser

- (id)init {
	self = [super init];
	if (self) {
		self.tokenKindTab = @{
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
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
    
    [self list]; 

    [self __fireAssemblerSelector:@selector(parser:didMatch__start:)];
}

- (void)list {
	//NSLog(@"list %@", self.assembly);
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchList:)];
}

- (void)elements {
	//NSLog(@"elements %@", self.assembly);
    
    [self element]; 
    while ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self element]; 
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchElements:)];
}

- (void)element {
	//NSLog(@"element %@", self.assembly);
    
    if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self __predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        [self list]; 
    } else {
        [PKSRecognitionException raise:NSStringFromClass([PKSRecognitionException class]) format:@"no viable alternative found in element"];
    }

    [self __fireAssemblerSelector:@selector(parser:didMatchElement:)];
}

- (void)lbracket {
	//NSLog(@"lbracket %@", self.assembly);
    
    [self __match:TOKEN_KIND_LBRACKET]; 

    [self __fireAssemblerSelector:@selector(parser:didMatchLbracket:)];
}

- (void)rbracket {
	//NSLog(@"rbracket %@", self.assembly);
    
    [self __match:TOKEN_KIND_RBRACKET]; [self __discard];

    [self __fireAssemblerSelector:@selector(parser:didMatchRbracket:)];
}

- (void)comma {
	//NSLog(@"comma %@", self.assembly);
    
    [self __match:TOKEN_KIND_COMMA]; [self __discard];

    [self __fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

@end