#import "MethodsParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self._assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self._assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self._assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *_assembly;
@end

@interface MethodsParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation MethodsParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
           @"int" : @(TOKEN_KIND_INT),
           @"}" : @(TOKEN_KIND_CLOSE_CURLY),
           @"," : @(TOKEN_KIND_COMMA),
           @"void" : @(TOKEN_KIND_VOID),
           @"(" : @(TOKEN_KIND_OPEN_PAREN),
           @"{" : @(TOKEN_KIND_OPEN_CURLY),
           @")" : @(TOKEN_KIND_CLOSE_PAREN),
           @";" : @(TOKEN_KIND_SEMI_COLON),
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
    
    do {
        [self method]; 
    } while (LA(1) == TOKEN_KIND_VOID || LA(1) == TOKEN_KIND_INT);

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)method {
    
    if ([self speculate:^{ [self testAndThrow:(id)^{ return NO; }]; [self type]; [self Word]; [self match:TOKEN_KIND_OPEN_PAREN]; [self args]; [self match:TOKEN_KIND_CLOSE_PAREN]; [self match:TOKEN_KIND_SEMI_COLON]; }]) {
        [self type]; 
        [self Word]; 
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self args]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
        [self match:TOKEN_KIND_SEMI_COLON]; 
    } else if ([self speculate:^{ [self testAndThrow:(id)^{ return 1; }]; [self type]; [self Word]; [self match:TOKEN_KIND_OPEN_PAREN]; [self args]; [self match:TOKEN_KIND_CLOSE_PAREN]; [self match:TOKEN_KIND_OPEN_CURLY]; [self match:TOKEN_KIND_CLOSE_CURLY]; }]) {
        [self type]; 
        [self Word]; 
        [self match:TOKEN_KIND_OPEN_PAREN]; 
        [self args]; 
        [self match:TOKEN_KIND_CLOSE_PAREN]; 
        [self match:TOKEN_KIND_OPEN_CURLY]; 
        [self match:TOKEN_KIND_CLOSE_CURLY]; 
    } else {
        [self raise:@"no viable alternative found in method"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchMethod:)];
}

- (void)type {
    
    if (LA(1) == TOKEN_KIND_VOID) {
        [self match:TOKEN_KIND_VOID]; 
    } else if (LA(1) == TOKEN_KIND_INT) {
        [self match:TOKEN_KIND_INT]; 
    } else {
        [self raise:@"no viable alternative found in type"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchType:)];
}

- (void)args {
    
    if (LA(1) == TOKEN_KIND_INT) {
        [self arg]; 
        while (LA(1) == TOKEN_KIND_COMMA) {
            [self match:TOKEN_KIND_COMMA]; 
            [self arg]; 
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArgs:)];
}

- (void)arg {
    
    [self match:TOKEN_KIND_INT]; 
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchArg:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end