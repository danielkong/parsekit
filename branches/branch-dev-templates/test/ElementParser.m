#import "ElementParser.h"

@implementation ElementParser

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
           @"[" : @(TOKEN_KIND_LBRACKET),
           @"]" : @(TOKEN_KIND_RBRACKET),
           @"," : @(TOKEN_KIND_COMMA),
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
    
    [self list]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatch_start:)]) {
        [self.assembler performSelector:@selector(parser:didMatch_start:) withObject:self withObject:self.assembly];
    }
}

- (void)list {
	NSLog(@"list %@", self.assembly);
    
    [self lbracket]; 
    [self elements]; 
    [self rbracket]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchList:)]) {
        [self.assembler performSelector:@selector(parser:didMatchList:) withObject:self withObject:self.assembly];
    }
}

- (void)elements {
	NSLog(@"elements %@", self.assembly);
    
    [self element]; 
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_COMMA), nil]]) {
        [self comma]; 
        [self element]; 
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchElements:)]) {
        [self.assembler performSelector:@selector(parser:didMatchElements:) withObject:self withObject:self.assembly];
    }
}

- (void)element {
	NSLog(@"element %@", self.assembly);
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_BUILTIN_NUMBER), nil]]) {
        [self Number]; 
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_KIND_LBRACKET), nil]]) {
        [self list]; 
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in element"];
    }

    if ([self.assembler respondsToSelector:@selector(parser:didMatchElement:)]) {
        [self.assembler performSelector:@selector(parser:didMatchElement:) withObject:self withObject:self.assembly];
    }
}

- (void)lbracket {
	NSLog(@"lbracket %@", self.assembly);
    
    [self match:TOKEN_KIND_LBRACKET]; 

    if ([self.assembler respondsToSelector:@selector(parser:didMatchLbracket:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLbracket:) withObject:self withObject:self.assembly];
    }
}

- (void)rbracket {
	NSLog(@"rbracket %@", self.assembly);
    
    [self match:TOKEN_KIND_RBRACKET]; [self discard];

    if ([self.assembler respondsToSelector:@selector(parser:didMatchRbracket:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRbracket:) withObject:self withObject:self.assembly];
    }
}

- (void)comma {
	NSLog(@"comma %@", self.assembly);
    
    [self match:TOKEN_KIND_COMMA]; [self discard];

    if ([self.assembler respondsToSelector:@selector(parser:didMatchComma:)]) {
        [self.assembler performSelector:@selector(parser:didMatchComma:) withObject:self withObject:self.assembly];
    }
}

@end