#import "MyParser.h"

@implementation MyParser

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

- (void)_start {
	NSLog(@"_start %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatch_Start:)]) {
        [self.preassembler performSelector:@selector(parser:willMatch_Start:) withObject:self withObject:self.assembly];
    }

    [self list];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatch_Start:)]) {
        [self.assembler performSelector:@selector(parser:didMatch_Start:) withObject:self withObject:self.assembly];
    }
}

- (void)list {
	NSLog(@"list %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchList:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchList:) withObject:self withObject:self.assembly];
    }

    [self lbracket];
    [self elements];
    [self rbracket];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchList:)]) {
        [self.assembler performSelector:@selector(parser:didMatchList:) withObject:self withObject:self.assembly];
    }
}

- (void)elements {
	NSLog(@"elements %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchElements:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchElements:) withObject:self withObject:self.assembly];
    }

    [self element];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_COMMA), nil]]) {
        [self comma];
        [self element];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchElements:)]) {
        [self.assembler performSelector:@selector(parser:didMatchElements:) withObject:self withObject:self.assembly];
    }
}

- (void)element {
	NSLog(@"element %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchElement:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchElement:) withObject:self withObject:self.assembly];
    }

    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_NUMBER), nil]]) {
        [self Number];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_LBRACKET), nil]]) {
        [self list];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in element"];
    }

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchElement:)]) {
        [self.assembler performSelector:@selector(parser:didMatchElement:) withObject:self withObject:self.assembly];
    }
}

- (void)lbracket {
	NSLog(@"lbracket %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchLbracket:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchLbracket:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_LBRACKET];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchLbracket:)]) {
        [self.assembler performSelector:@selector(parser:didMatchLbracket:) withObject:self withObject:self.assembly];
    }
}

- (void)rbracket {
	NSLog(@"rbracket %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchRbracket:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchRbracket:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_RBRACKET];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchRbracket:)]) {
        [self.assembler performSelector:@selector(parser:didMatchRbracket:) withObject:self withObject:self.assembly];
    }
}

- (void)comma {
	NSLog(@"comma %@", self.assembly);
    
    if (self.preassembler && [self.preassembler respondsToSelector:@selector(parser:willMatchComma:)]) {
        [self.preassembler performSelector:@selector(parser:willMatchComma:) withObject:self withObject:self.assembly];
    }

    [self match:TOKEN_TYPE_COMMA];

    if (self.assembler && [self.assembler respondsToSelector:@selector(parser:didMatchComma:)]) {
        [self.assembler performSelector:@selector(parser:didMatchComma:) withObject:self withObject:self.assembly];
    }
}

@end