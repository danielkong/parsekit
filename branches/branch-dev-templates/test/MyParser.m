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

- (NSInteger)userTypeForString:(NSString *)name {
    static NSDictionary *d = nil;
    if (!d) {
        d = [@{
             @"[" : @(TOKEN_TYPE_LBRACKET),
             @"]" : @(TOKEN_TYPE_RBRACKET),
             @"," : @(TOKEN_TYPE_COMMA),
             } retain];
    }
    
    NSInteger x = [super builtInUserTypeForString:name];
    if (TOKEN_TYPE_BUILTIN_INVALID == x) {
        id obj = d[[name uppercaseString]];
        if (obj) {
            x = [obj integerValue];
        }
    }
    return x;
}


- (void)_start {
	NSLog(@"_start");
    
    [self list];
}

- (void)list {
	NSLog(@"list");
    
    [self lbracket];
    [self elements];
    [self rbracket];
}

- (void)elements {
	NSLog(@"elements");
    
    [self element];
    while ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_COMMA), nil]]) {
        [self comma];
        [self element];
    }
}

- (void)element {
	NSLog(@"element");
    
    if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_BUILTIN_WORD), nil]]) {
        [self Word];
    } else if ([self predicts:[NSSet setWithObjects:@(TOKEN_TYPE_LBRACKET), nil]]) {
        [self list];
    } else {
        [NSException raise:@"PKRecongitionException" format:@"no viable alternative found in |"];
    }
}

- (void)lbracket {
	NSLog(@"lbracket");
    
    [self match:TOKEN_TYPE_LBRACKET];
}

- (void)rbracket {
	NSLog(@"rbracket");
    
    [self match:TOKEN_TYPE_RBRACKET];
}

- (void)comma {
	NSLog(@"comma");
    
    [self match:TOKEN_TYPE_COMMA];
}

@end