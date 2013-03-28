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

- (NSInteger)tokenUserTypeForString:(NSString *)name {
    static NSDictionary *d = nil;
    if (!d) {
        d = [@{
           @"[" : @(TOKEN_TYPE_LBRACKET),
           @"]" : @(TOKEN_TYPE_RBRACKET),
           @"," : @(TOKEN_TYPE_COMMA),
        } retain];
    }
    
    NSInteger x = TOKEN_TYPE_BUILTIN_INVALID;
    id obj = d[name];
    if (obj) {
        x = [obj integerValue];
    }
    return x;
}

- (void)_start:(BOOL)discard {
	NSLog(@"_start %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatch_start:)]) {
        [self.preassembler performSelector:@selector(parser:willMatch_start:) withObject:self withObject:self.assembly];
    }

    [self list:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatch_start:)]) {
        [self.assembler performSelector:@selector(parser:didMatch_start:) withObject:self withObject:self.assembly];
    }
}

- (void)list:(BOOL)discard {
	NSLog(@"list %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchList:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchList:) withObject:self withObject:self.assembly];
    }

    [self lbracket:NO];
    [self elements:NO];
    [self rbracket:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchList:)]) {
        [self.assembler performSelector:@selector(parser:didMatchList:) withObject:self withObject:self.assembly];
    }
}

- (void)elements:(BOOL)discard {
	NSLog(@"elements %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchElements:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchElements:) withObject:self withObject:self.assembly];
    }

    [self element:NO];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_COMMA), nil]]) {
        [self comma:NO];
        [self element:NO];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchElements:)]) {
        [self.assembler performSelector:@selector(parser:didMatchElements:) withObject:self withObject:self.assembly];
    }
}

- (void)element:(BOOL)discard {
	NSLog(@"element %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchElement:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchElement:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_NUMBER), nil]]) {
        [self Number:NO];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_LBRACKET), nil]]) {
        [self list:NO];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in element"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchElement:)]) {
        [self.assembler performSelector:@selector(parser:didMatchElement:) withObject:self withObject:self.assembly];
    }
}

- (void)lbracket:(BOOL)discard {
	NSLog(@"lbracket %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchLbracket:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchLbracket:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_LBRACKET andDiscard:NO];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchLbracket:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLbracket:) withObject:self withObject:self.assembly];
    }
}

- (void)rbracket:(BOOL)discard {
	NSLog(@"rbracket %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchRbracket:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchRbracket:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_RBRACKET andDiscard:YES];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchRbracket:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRbracket:) withObject:self withObject:self.assembly];
    }
}

- (void)comma:(BOOL)discard {
	NSLog(@"comma %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchComma:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchComma:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_COMMA andDiscard:YES];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchComma:)]) {
        [self.assembler performSelector:@selector(parser:didMatchComma:) withObject:self withObject:self.assembly];
    }
}

@end